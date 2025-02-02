# QEMU guest configuration
# Creates a virtual machine from the NixOS configuration using the `config.system.build.vm` target 
# which will create a series of scripts in result/bin that can be used to manage the VM.
#
# ### References:
# - [SPICE User manual](https://www.spice-space.org/spice-user-manual.html)
# - [QEMU VM module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/virtualisation/qemu-vm.nix)
#
# ### Goals:
# - High performance NixOS only VM configuration
#   - Case 1: Full GPU accelerated system with audio passthrough and bridged LAN membership
#   - Case 2: Headless server with optional bridged networking
# 
# ### Features:
# - makes use of direct boot rather than using a bootloader
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.qemu.guest;

  # The msize (maximum packet size) passed to 9p file systems, in bytes. Increasing this
  # should increase performance significantly, at the cost of higher RAM usage.
  msize9p = 16384;

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) cfg.interfaces;
  userInterfaces = interfacesByType "user";
  macvtapInterfaces = interfacesByType "macvtap";

  regInfo = pkgs.closureInfo { rootPaths = cfg.registeredPaths; };
in
{
  imports = [
    ./macvtap.nix
    ./run.nix
  ];

  options = {
    virtualisation.qemu.guest = {
      package = lib.mkOption {
        description = ''
          There are a few binaries available. `qemu-kvm` is an older packaging concept. For NixOS use
          qemu-system-x86_64 which is pkgs.qemu_kvm in Nix land.
        '';
        type = types.package;
        default = pkgs.qemu_kvm;
      };
      store = lib.mkOption {
        description = "Configure the nix store";
        type = types.submodule {
          options = {
            mountHost = lib.mkOption {
              description = ''
                Mount the host Nix store as a 9p mount. For performance reasons consider building and
                using a disk image for the Nix store and use a binary cache to improve hits.
              '';
              type = types.bool;
              default = true;
            };
            useImage = lib.mkOption {
              description = lib.mdDoc ''
                Build and use a disk image for the Nix store, instead of accessing the host's through a
                9p mount. This will drastically improve performance, but at the cost of disk space and
                image built time.
              '';
              type = types.bool;
              default = false;
            };
          };
        };
        default = {
          mountHost = true;
          useImage = false;
        };
      };
      rootDrive = lib.mkOption {
        description = "Configure the root drive";
        type = types.submodule {
          options = {
            size = lib.mkOption {
              description = "Root disk size in GB";
              type = types.int;
              default = 1;
            };
            image = lib.mkOption {
              description = "Root image name";
              type = types.str;
              default = "./${machine.hostname}.qcow2";
            };
            label = lib.mkOption {
              description = "Root drive label";
              type = types.str;
              default = "nixos";
            };
            pathVar = lib.mkOption {
              description = "Root drive runtime path variable";
              type = types.str;
              default = "ROOT_IMAGE";
            };
          };
        };
        default = {
          size = 1;
          image = "./${machine.hostname}.qcow2";
          label = "nixos";
          pathVar = "ROOT_IMAGE";
        };
      };
      cores = lib.mkOption {
        description = lib.mdDoc "Number of virtual cores for VM";
        type = types.int;
        default = 2;
      };
      memorySize = lib.mkOption {
        description = lib.mdDoc "Memory size in GB for VM";
        type = types.int;
        default = 4;
      };
      virtioKeyboard = lib.mkOption {
        description = lib.mdDoc ''Enable the virtio-keyboard device.'';
        type = types.bool;
        default = true;
      };
      usb = lib.mkOption {
        description = lib.mdDoc ''Enable USB support.'';
        type = types.bool;
        default = true;
      };
      display = lib.mkOption {
        description = lib.mdDoc "Configure display for VM";
        type = types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable display";
            memory = lib.mkOption {
              description = lib.mdDoc ''
                Video memory size in MB for VM.
                - This value must be in powers of two.
                - The valid range is 1 MB to 256 MB.
              '';
              type = types.int;
              default = 16;
            };
          };
        };
        default = if (machine.vm.local) then {
          enable = true;
          memory = 32;
        } else {
          enable = false;
          memory = 16;
        };
      };
      audio = lib.mkOption {
        description = lib.mdDoc "Enable sound for VM";
        type = types.bool;
        default = if (!machine.vm.micro) then true else false;
      };
      spice = lib.mkOption {
        description = "SPICE configuration";
        type = types.submodule {
          options = {
            enable = lib.mkEnableOption "Enable SPICE";
            port = lib.mkOption {
              description = lib.mdDoc "SPICE port for VM";
              type = types.int;
              default = 5970;
            };
          };
        };
        default = {
          enable = if (machine.vm.spice) then true else false;
          port = 5970;
        };
      };
      interfaces = lib.mkOption {
        description = ''
          Network interface options. 
          - Use `type = "user"` for a simple NAT experience. 
          - Use `type = "macvtap"` for a full presence on the LAN.
        '';
        type = types.listOf (types.submodule {
          options = {
            type = lib.mkOption {
              type = types.enum [ "user" "macvtap" ];
              description = "Interface type";
            };
            id = lib.mkOption {
              type = types.str;
              description = "Interface name on the host. e.g. `vm-prod1@enp1s0`";
              example = "vm-prod1";
            };
            fd = lib.mkOption {
              type = types.int;
              description = "File descriptor number";
              example = 3;
            };
            macvtap.link = lib.mkOption {
              type = types.str;
              description = "Host NIC to attach to";
            };
            macvtap.mode = lib.mkOption {
              type = types.enum [ "bridge" ];
              description = "The MACVTAP mode to use";
            };
            mac = lib.mkOption {
              type = types.str;
              description = ''
                MAC address of the guest's network interface. Setting it to a prefix of 02 indicates 
                that it is being adminstered locally. Then you can simply increment the final nibble 
                to provide unique identifiers for your VMs.
              '';
              example = "02:00:00:00:00:01";
            };
          };
        });

        # Default the networking to use a user mode NAT device
        default = [{
          type = "user";
          id = machine.hostname;
        }];
      };
      registeredPaths = lib.mkOption {
        type = types.listOf types.path;
        description = lib.mdDoc ''
          A list of paths whose closure should be made available to the VM.

          When 9p is used, the closure is registered in the Nix database in the VM. All other paths
          in the host Nix store appear in the guest Nix store as well, but are considered garbage
          (because they are not registered in the Nix database of the guest).
        '';
        default = [ config.system.build.toplevel ];
      };

      scripts = lib.mkOption {
        description = "VM startup scripts";
        type = types.submodule {
          options = {
            run = lib.mkOption {
              type = types.str;
              description = "QEMU startup script";
              default = "";
            };
            macvtap-up = lib.mkOption {
              type = types.str;
              description = "Macvtap startup script";
              default = "";
            };
            macvtap-down = lib.mkOption {
              type = types.str;
              description = "Macvtap shutdown script";
              default = "";
            };
          };
        };
      };

      options = lib.mkOption {
        type = types.listOf types.str;
        description = lib.mdDoc ''
          Pass through arguments to the QEMU run function call. Will be filled out by configuration
          automation down below based on guest input options.
        '';
        example = [
          "-net nic,netdev=vm-prod1,model=virtio"
          "-netdev user,id=vm-prod1"
        ];
        default = [ ];
      };
    };
  };

  config = lib.mkMerge [
    {
      services.qemuGuest.enable = true;                   # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;         # We'll use SPICE instead
      networking.wireless.enable = lib.mkForce false;     # Wireless networking won't work in VM
      services.connman.enable = lib.mkForce false;        # Wireless networking won't work in VM
      networking.dhcpcd.extraConfig = "noarp";            # Speed up booting by not waiting for ARP
      services.timesyncd.enable = false;                  # VM should get correct time from KVM
      swapDevices = lib.mkForce [ ];                      # Disable swap for vms
      boot.initrd.luks.devices = lib.mkForce {};          # Disable luks for vms

      # Configure xserver defaults for VM
      services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
      services.xserver.defaultDepth = lib.mkForce 0;
      services.xserver.monitorSection = ''
        # Set a higher refresh rate so that resolutions > 800x600 work.
        HorizSync 30-140
        VertRefresh 50-160
      '';

      # QEMU VM kernel configuration
      # --------------------------------------------
      boot.loader.grub.device = lib.mkForce "/dev/disk/by-id/virtio-${cfg.rootDrive.label}";
      boot.loader.grub.gfxmodeBios = with machine.resolution; "${toString x}x${toString y}";
      boot.loader.supportsInitrdSecrets = lib.mkForce false;
      boot.initrd.availableKernelModules = [
        "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi"
        "9p" "9pnet_virtio"
      ] ++ lib.optionals (cfg.store.mountHost) [ "overlay" ];

      boot.initrd.kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_pci"
        "virtio_rng"
      ];
      boot.initrd.postDeviceCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
        # Set the system time from the hardware clock to work around a bug in qemu-kvm > 1.5.2 (where
        # the VM clock is initialised to the *boot time* of the host).
        hwclock -s
      '';
      system.requiredKernelConfig = with config.lib.kernelConfig; [
        (isEnabled "VIRTIO_BLK") (isEnabled "VIRTIO_PCI") (isEnabled "VIRTIO_NET")
        (isEnabled "EXT4_FS") (isEnabled "NET_9P_VIRTIO") (isEnabled "9P_FS")
        (isYes "BLK_DEV") (isYes "PCI") (isYes "NETDEVICES") (isYes "NET_CORE")
        (isYes "INET") (isYes "NETWORK_FILESYSTEMS")
      ] ++ optionals (!cfg.display.enable) [
        (isYes "SERIAL_8250_CONSOLE") (isYes "SERIAL_8250")
      ] ++ optionals (cfg.store.mountHost) [
        (isEnabled "OVERLAY_FS")
      ];
      systemd.tmpfiles.rules = lib.mkIf config.boot.initrd.systemd.enable [
        "f /etc/NIXOS 0644 root root -"
        "d /boot 0644 root root -"
      ];
      boot.initrd.postMountCommands = lib.mkIf (!config.boot.initrd.systemd.enable)
        ''
          # Mark this as a NixOS machine.
          mkdir -p $targetRoot/etc
          echo -n > $targetRoot/etc/NIXOS

          # Fix the permissions on /tmp.
          chmod 1777 $targetRoot/tmp

          mkdir -p $targetRoot/boot

          ${lib.optionalString cfg.store.mountHost ''
            echo "mounting overlay filesystem on /nix/store..."
            mkdir -p -m 0755 $targetRoot/nix/.rw-store/store $targetRoot/nix/.rw-store/work $targetRoot/nix/store
            mount -t overlay overlay $targetRoot/nix/store \
              -o lowerdir=$targetRoot/nix/.ro-store,upperdir=$targetRoot/nix/.rw-store/store,workdir=$targetRoot/nix/.rw-store/work || fail
          ''}
        '';

      # After booting, register the closure of the paths in `registeredPaths' in the Nix
      # database in the VM.  This allows Nix operations to work in the VM.  The path to the
      # registration file is passed through the kernel command line to allow `system.build.toplevel' to
      # be included.  (If we had a direct reference to ${regInfo} here, then we would get a cyclic
      # dependency.)
      boot.postBootCommands = lib.mkIf config.nix.enable
        ''
          if [[ "$(cat /proc/cmdline)" =~ regInfo=([^ ]*) ]]; then
            ${config.nix.package.out}/bin/nix-store --load-db < ''${BASH_REMATCH[1]}
          fi
        '';

      boot.initrd.systemd = lib.mkIf (config.boot.initrd.systemd.enable && cfg.store.mountHost) {
        mounts = [{
          where = "/sysroot/nix/store";
          what = "overlay";
          type = "overlay";
          options = "lowerdir=/sysroot/nix/.ro-store,upperdir=/sysroot/nix/.rw-store/store,workdir=/sysroot/nix/.rw-store/work";
          wantedBy = ["initrd-fs.target"];
          before = ["initrd-fs.target"];
          requires = ["rw-store.service"];
          after = ["rw-store.service"];
          unitConfig.RequiresMountsFor = "/sysroot/nix/.ro-store";
        }];
        services.rw-store = {
          unitConfig = {
            DefaultDependencies = false;
            RequiresMountsFor = "/sysroot/nix/.rw-store";
          };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/bin/mkdir -p -m 0755 /sysroot/nix/.rw-store/store /sysroot/nix/.rw-store/work /sysroot/nix/store";
          };
        };
      };

      # Filesystem configuration
      # --------------------------------------------
      fileSystems = lib.mkForce {
        "/" = {
          device = "/dev/disk/by-label/${cfg.rootDrive.label}";
          fsType = "ext4";
        };
        "/tmp" = lib.mkIf config.boot.tmp.useTmpfs {
          device = "tmpfs";
          fsType = "tmpfs";
          neededForBoot = true;
          # Sync with systemd's tmp.mount;
          options = [ "mode=1777" "strictatime" "nosuid" "nodev" "size=${toString config.boot.tmp.tmpfsSize}" ];
        };

        # Simple directory share between host and guest
        "/tmp/shared" = {
          device = "shared";
          fsType = "9p";
          neededForBoot = true;
          options = [ "trans=virtio" "version=9p2000.L"  "msize=${toString msize9p}" ];
        };

        # Mount the host store as read only and then create a writable non-persistent tmpfs
        # mount point that will then be layered over it during the boot.initrd.postMountCommands
        "/nix/.ro-store" = lib.mkIf (cfg.store.mountHost) {
          device = "nix-store";
          fsType = "9p";
          neededForBoot = true;
          options = [ "trans=virtio" "version=9p2000.L"  "msize=${toString msize9p}" "cache=loose" ];
        };
        "/nix/.rw-store" = lib.mkIf (cfg.store.mountHost) {
          fsType = "tmpfs";
          options = [ "mode=0755" ];
          neededForBoot = true;
        };

        # TODO: Build out a writable drive store
#        "/nix/store" = lib.mkIf (cfg.store.useImage) {
#          device = "/dev/disk/by-label/nix-store";
#          neededForBoot = true;
#          options = [ "ro" ];
#        };
      };

      # [QEMU launch options](https://qemu-project.gitlab.io/qemu/system/invocation.html)
      # --------------------------------------------------------------------------------------------
      virtualisation.qemu.guest.options =
        [
          "-name ${machine.hostname}"         # Name to use for GUI windows and process names
          "-pidfile ${machine.hostname}.pid"  # Store the QEMU process PID in this file
          "-nodefaults -no-user-config"       # Disable any defaults or pass throughs for a clean env
        ]

        # QEMU supports two full x86 chipsets; the ancient (1996) i440FX and the more recent (2007) Q35. 
        # Q35 is the defacto standard for anything modern looking for performance.
        ++ lib.optionals (!machine.vm.micro) [("-machine " + (lib.concatStringsSep "," [
          "q35"                               # Q35 is modern solution supporting PCIe natively
          "accel=kvm"                         # Means the same as older --enable-kvm form
          "smm=off"                           # System Mgmt Mode is part of secure boot and not needed
          "vmport=off"                        # Disables VMWare IO port emulation
        ]))]

        # QEMU also supports the [microvm](https://www.qemu.org/docs/master/system/i386/microvm.html)
        # machine type which is a modern slimmed down x86 that can be used for headless servers.
        ++ lib.optionals (machine.vm.micro) [("-machine " + (lib.concatStringsSep "," [
          "microvm"                           # Modern minimal type without PCI or ACPI
          "accel=kvm"                         # Means the same as older --enable-kvm form
          "acpi=on"                           # Allow event handling of shutdown
          "mem-merge=on"                      # Enable memory merge support optimization
          "pcie=on"                           # Ensure PCIe support is on
          "pic=off"                           # Disable i8259 PIC and use kvmclock instead
          "pit=off"                           # Disable i8254 PIT and use kvmclock instead
          "usb=off"                           # No need for usb in a microvm
        ]))]

        # Optimal performance is found with host cpu type and x2apic enabled.
        # * -smp has other options but using them provides no added performance
        ++ [("-smp ${toString cfg.cores} -cpu " + (lib.concatStringsSep "," [
          "host"                              # Optimal performance setting even over -cpu max
          "+x2apic"                           # performance feature that has no downs for x86 guests
          "-sgx"                              # disabling: https://gitlab.com/qemu-project/qemu/-/issues/2142
        ]))]

        # VirtIO Memory Ballooning allows the host and guest to more intelligently manage memory such
        # that the host can reclaim and negociate with the guest how much is used.
        ++ [ "-m ${toString cfg.memorySize}G -device virtio-balloon" ]

        ++ [ "-device virtio-rng-pci" ]       # Use a virtio driver for randomness

        ++ lib.optionals (machine.vm.micro && cfg.virtioKeyboard) [
          "-device i8042"                     # Keyboard controller supporting ctrl+alt+del
        ]
        ++ lib.optionals (!machine.vm.micro && cfg.virtioKeyboard) [
          "-device virtio-keyboard"           # ?
        ]
        ++ lib.optionals (!machine.vm.micro && cfg.usb) [
          "-usb -device usb-tablet,bus=usb-bus.0"
        ]

        # Drive configuration
        # --------------------------------------------
        ++ [ # Root drive created by the run script and passed into QEMU here
          ''-drive cache=writeback,file="''$${cfg.rootDrive.pathVar}",id=drive1,if=none,index=1,werror=report''
          "-device virtio-blk-pci,bootindex=1,drive=drive1,serial=${cfg.rootDrive.label}"
        ]
        #(mkIf guest.store.useImage [{ name = "nix-store"; file = ''"$TMPDIR"/store.img'';
        #  deviceExtraOpts.bootindex = "2"; driveExtraOpts.format = "raw";
        #}])

        # Shared folders configuration consists of two parts:
        # 1. QEMU configuration to make make it available
        # 2. Guest OS configuration so it know what to do with it
        # ----------------------------------------------
        # Simple mapping between host $pwd/$vm/shared and guest /tmp/shared
        ++ [ ''-virtfs local,path="$VMDIR"/shared,security_model=none,mount_tag=shared'' ]

        # Mount the nix store as a share
        ++ lib.optionals (cfg.store.mountHost) [
          "-virtfs local,path=${builtins.storeDir},security_model=none,mount_tag=nix-store"
        ]
        # TODO: add support for optional shares if I have a need
        #(lib.mapAttrsToList (tag: share:
        #  "-virtfs local,path=${share.source},security_model=none,mount_tag=${tag}"
        #) cfg.sharedDirectories)

        # Networking configuration
        ++ lib.optionals (macvtapInterfaces != [])
          (builtins.concatMap (x: [
            "-netdev tap,id=${x.id},fd=${toString x.fd}"
            "-device virtio-net-pci,netdev=${x.id},mac=${x.mac}"
          ]) macvtapInterfaces)
        ++ lib.optionals (userInterfaces != [])
          (builtins.concatMap (x: [
            "-netdev user,id=${x.id}"
            "-device virtio-net-pci,netdev=${x.id}"
          ]) userInterfaces)

        # Audio configuration
        # -----------------------------------------------
        # https://www.kraxel.org/blog/2020/01/qemu-sound-audiodev/
        # -device provides the sound card while -audiodev maps to the host's backend
        # 
        # Other notes:
        # -audiodev pipewire,id=snd0
        # -audio driver=pa,model=virtio,server=/run/user/1000/pulse/
        # -device intel-hda -device hda-output,audiodev=snd0
        # -device ich9-intel-hda -device hda-output,audiodev=snd0
        ++ lib.optionals (cfg.audio) (
          if (cfg.spice.enable) then [
            # Mostly works, but tends to sputter some times
            "-audiodev spice,id=snd0"                     # SPICE as the host backend
            "-device virtio-sound-pci,audiodev=snd0"
          ] else [
            "-audiodev pipewire,id=snd0"                  # Pipewire as the host backend
            "-device virtio-sound-pci,audiodev=snd0"      # Virtio sound card
          ]
        )

        # Display configuration
        # -----------------------------------------------
        # Virtio GPU with Virglrenderer supported accelerated graphics
        # * https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-3
        # * -display gtk
        # * -display spice-app,gl=on
        # * -display gtk,gl=on,grab-on-hover=on,window-close=on,zoom-to-fit=on
        ++ lib.optionals (machine.vm.local && cfg.display.enable) [
          "-vga none -device virtio-vga-gl"
          "-display sdl,gl=on"
        ]

        # Hmm, seems to collide with my serial output settings below
        ++ lib.optionals (machine.vm.micro || !cfg.display.enable) [
          "-nographic"                                    # Disable the local GUI window
        ]

        # SPICE configuration
        # ----------------------------------------------
        # - Connect by launching `remote-viewer` and running `spice://localhost:5970`
        # - working copy and past to and from the VM via remote-viewer
        # - https://www.qemu.org/docs/master/system/devices/virtio-gpu.html
        # - SPICE needs a unix socket connection for opengl to work
        # - glxgears --info
        # - QXL defaults to 16 MB video memory, but needs 32MB min for high quality 
        # - -vga qxl vs -device qxl-vga
        ++ lib.optionals (machine.vm.spice || cfg.spice.enable) [
          "-vga qxl"
          "-device virtio-serial-pci"
          "-spice port=${toString cfg.spice.port},disable-ticketing=on"
          "-chardev spicevmc,id=${machine.hostname},debug=0,name=vdagent"
          "-device virtserialport,chardev=${machine.hostname},name=com.redhat.spice.0"
        ]

        # Kernel configuration
        # ----------------------------------------------
        ++ [
          "-kernel ${config.system.build.toplevel}/kernel"
          "-initrd ${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}"
          (''-append "'' + (lib.concatStringsSep " " [
            "earlyprintk=ttyS0"                           # Redirect early kernel logging to vm's first serial port ttyS0
            "console=ttyS0"                               # Redirect kernel output to vm's first serial port ttyS0
            "net.ifnames=0"                               # Use predictable interface names
            "loglevel=4"                                  # Set kernel log level to 4 
            "init=${config.system.build.toplevel}/init"   # Init
            "regInfo=${regInfo}/registration"             # Nix store registration
          ]) + ''"'')
        ]

        # By redirection all output to serial above in the 'append' section then redirecting serial 
        # to the host stdio below we get all VM output showing up on stdio like a normal application.
        # Note: this collides with the -nographic which does something similar
        #++ lib.optionals (!machine.vm.micro) [
        ++ [
          "-chardev 'stdio,id=stdio,signal=off'"          # Create char device for stdio
          "-serial chardev:stdio"                         # Redirect all VM's serial output named chardev
        ];

      # Build the VM and create the startup/shutdown scripts
      # --------------------------------------------------------------------------------------------
      system.build.vm = lib.mkForce (pkgs.runCommand "${machine.hostname}" { preferLocalBuild = true; } ''
        mkdir -p $out/bin
        ln -s ${config.system.build.toplevel} $out/system
        ln -s ${pkgs.writeScript "run-${machine.hostname}" cfg.scripts.run} $out/bin/run

        # Optionally configure macvtap scripts
        if [[ "${if macvtapInterfaces != [] then "1" else "0"}" == "1" ]]; then
          ln -s ${pkgs.writeScript "macvtap-up" cfg.scripts.macvtap-up} $out/bin/macvtap-up
          ln -s ${pkgs.writeScript "macvtap-down" cfg.scripts.macvtap-down} $out/bin/macvtap-down
        fi
      '');
    }

    # Configure SPICE services on the Guest OS
    (lib.mkIf (machine.vm.spice || cfg.spice.enable) {
      services.spice-autorandr.enable = true;       # Automatically adjust resolution of guest to spice client size
      services.spice-vdagentd.enable = true;        # SPICE agent to be run on the guest OS
      services.spice-webdavd.enable = true;         # Enable file sharing on guest to allow access from host

      # Install and configure higher performance display driver QXL for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];
      #services.xserver.videoDrivers = [ "virtio" ];
      #environment.systemPackages = [ pkgs.virglrenderer ];

      # Open up the firewall for machine.vm.spicePort
      networking.firewall.allowedTCPPorts = [ cfg.spice.port ];
    })
  ];
}
