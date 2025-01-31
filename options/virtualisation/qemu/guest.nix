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
  fixme = config.virtualisation;
  cfg = config.virtualisation.qemu.guest;

  # Identifiers
  nixStoreLabel = "nix-store";

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) cfg.interfaces;
  userInterfaces = interfacesByType "user";
  macvtapInterfaces = interfacesByType "macvtap";
in
{
  imports = [
    ./qemu-vm.nix
    ./macvtap.nix
    ./run.nix
  ];

  options = {
    virtualisation.qemu.guest = {
      enable = lib.mkEnableOption "Configure the VM's guest OS";
      package = lib.mkOption {
        description = "Standard KVM supported QEMU package";
        type = types.package;
        default = pkgs.qemu_kvm;
      };
      cores = lib.mkOption {
        description = lib.mdDoc "Number of virtual cores for VM";
        type = types.int;
        default = 1;
      };
      store = lib.mkOption {
        description = "Configure the nix store";
        type = (types.submodule {
          options.mountHost = lib.mkOption {
            description = ''
              Mount the host Nix store as a 9p mount. For performance reasons consider building and 
              using a disk image for the Nix store and use a binary cache to improve hits.
            '';
            type = types.bool;
          };
          options.useImage = lib.mkOption {
            type = types.bool;
            description = lib.mdDoc ''
              Build and use a disk image for the Nix store, instead of accessing the host's through a 
              9p mount. This will drastically improve performance, but at the cost of disk space and 
              image built time.
            '';
          };
        });
        default = {
          mountHost = true;
          useImage = false;
        };
      };
      rootDrive = lib.mkOption {
        description = "Configure the root drive";
        type = (types.submodule {
          options = {
            size = lib.mkOption {
              description = "Root disk size in GB";
              type = types.int;
            };
            image = lib.mkOption {
              description = "Root image name";
              type = types.str;
            };
            label = lib.mkOption {
              description = "Root drive label";
              type = types.str;
            };
            pathVar = lib.mkOption {
              description = "Root drive runtime path variable";
              type = types.str;
            };
          };
        });
        default = {
          size = 1;
          image = "./${machine.hostname}.qcow2";
          label = "nixos";
          pathVar = "ROOT_IMAGE";
        };
      };
      memorySize = lib.mkOption {
        description = lib.mdDoc "Memory size in GB for VM";
        type = types.int;
        default = 4;
      };
      display = lib.mkOption {
        description = lib.mdDoc "Configure display for VM";
        type = (types.submodule {
          options.enable = lib.mkEnableOption "Enable display";
          options.memory = lib.mkOption {
            description = lib.mdDoc ''
              Video memory size in MB for VM.
              - This value must be in powers of two.
              - The valid range is 1 MB to 256 MB.
            '';
            type = types.int;
            default = 16;
          };
        });
      };
      audio = lib.mkOption {
        description = lib.mdDoc "Enable audio for VM";
        type = types.bool;
        default = false;
      };
      virtioKeyboard = lib.mkOption {
        description = lib.mdDoc ''Enable the virtio-keyboard device.'';
        type = types.bool;
        default = true;
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
      };
      interfaces = lib.mkOption {
        description = ''
          Network interface options. 
          - Use `type = "user"` for a simple NAT experience. 
          - Use `type = "macvtap"` for a full presence on the LAN.
        '';
        default = [];
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
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (machine.type.vm) {
      services.qemuGuest.enable = true;                 # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;       # We'll use SPICE instead

      # QEMU VM kernel configuration
      # --------------------------------------------
      boot.loader.grub.device = "/dev/disk/by-id/virtio-${cfg.rootDrive.label}";
      boot.initrd.availableKernelModules = [
        "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi"
        "9p" "9pnet_virtio"
      ] ++ lib.optionals (cfg.store.mountHost) [ "overlay" ];

      boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];
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

      boot.initrd.postMountCommands = lib.mkIf (!config.boot.initrd.systemd.enable) ''
        # Mark this as a NixOS machine.
        mkdir -p $targetRoot/etc
        echo -n > $targetRoot/etc/NIXOS

        # Fix the permissions on /tmp.
        chmod 1777 $targetRoot/tmp

        mkdir -p $targetRoot/boot

        ${lib.optionalString (cfg.store.mountHost) ''
          echo "mounting writable tmpfs overlay on /nix/store..."
          mkdir -p -m 0755 $targetRoot/nix/.rw-store/store $targetRoot/nix/.rw-store/work $targetRoot/nix/store
          mount -t overlay overlay $targetRoot/nix/store \
            -o lowerdir=$targetRoot/nix/.ro-store,upperdir=$targetRoot/nix/.rw-store/store,workdir=$targetRoot/nix/.rw-store/work || fail
        ''}
      '';

      # Other VM configuration
      # --------------------------------------------
      networking.wireless.enable = lib.mkForce false;   # Wireless networking won't work in VM
      services.connman.enable = lib.mkForce false;      # Wireless networking won't work in VM
      networking.dhcpcd.extraConfig = "noarp";          # Speed up booting by not waiting for ARP
      networking.usePredictableInterfaceNames = false;  # ???
      services.timesyncd.enable = false;                # VM should get correct time from KVM

      # Filesystem configuration
      # --------------------------------------------
      fileSystems = lib.mkForce {
        "/" = {
          device = cfg.rootDrive.label;
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
          options = [ "trans=virtio" "version=9p2000.L"  "msize=${toString fixme.msize}" ];
        };

#        "/nix/.ro-store" = lib.mkIf (cfg.store.useImage) {
#          device = "/dev/disk/by-label/${nixStoreFilesystemLabel}";
#          neededForBoot = true;
#          options = [ "ro" ];
#        };

        # Mount the host store as read only and then create a writable non-persistent tmpfs
        # mount point that will then be layered over it during the boot.initrd.postMountCommands
        "/nix/.ro-store" = lib.mkIf (cfg.store.mountHost) {
          device = nixStoreLabel;
          fsType = "9p";
          neededForBoot = true;
          options = [ "trans=virtio" "version=9p2000.L"  "msize=${toString fixme.msize}" "cache=loose" ];
        };
        "/nix/.rw-store" = lib.mkIf (cfg.store.mountHost) {
          fsType = "tmpfs";
          options = [ "mode=0755" ];
          neededForBoot = true;
        };
      };

      virtualisation.qemu.options =

        # Drive configuration
        # --------------------------------------------
        [ # Root drive created by the run script and passed into QEMU here
          ''-drive cache=writeback,file="''$${cfg.rootDrive.pathVar}",id=drive1,if=none,index=1,werror=report''
          "-device virtio-blk-pci,bootindex=1,drive=drive1,serial=${cfg.rootDrive.label}"
        ]
        #(mkIf guest.store.useImage [{ name = "nix-store"; file = ''"$TMPDIR"/store.img'';
        #  deviceExtraOpts.bootindex = "2"; driveExtraOpts.format = "raw";
        #}])

        # Accessories configuration
        # --------------------------------------------
        ++ lib.optionals (cfg.virtioKeyboard) [
          "-device virtio-keyboard"
        ]
        ++ lib.optionals (pkgs.stdenv.hostPlatform.isx86) [
          "-usb" "-device usb-tablet,bus=usb-bus.0"
        ]

        # Shared folders configuration
        # ----------------------------------------------
        ++ [ # Simple mapping between host $pwd/$vm/shared and guest /tmp/shared
          ''-virtfs local,path="$VMDIR"/shared,security_model=none,mount_tag=shared''
        ]
        ++ lib.optionals (cfg.store.mountHost) [
          "-virtfs local,path=${builtins.storeDir},security_model=none,mount_tag=${nixStoreLabel}"
        ]
        # TODO: add support for optional shares if I have a need
        #(lib.mapAttrsToList (tag: share:
        #  "-virtfs local,path=${share.source},security_model=none,mount_tag=${tag}"
        #) cfg.sharedDirectories)

        # Networking configuration
        # --------------------------------------------
        # user: -net nic,netdev=vm-prod1,model=virtio -netdev user,id=vm-prod1
        # macvtap: -netdev tap,id=vm-prod1,fd=3 -device virtio-net-pci,netdev=vm-prod1,mac=02:00:00:00:00:01
        ++ lib.optionals (macvtapInterfaces != [])
          (builtins.concatMap (x: [
            "-netdev tap,id=${x.id},fd=${toString x.fd}"
            "-device virtio-net-pci,netdev=${x.id},mac=${x.mac}"
          ]) macvtapInterfaces)
        ++
        lib.optionals (userInterfaces != [])
          (builtins.concatMap (x: [
            "-netdev user,id=${x.id}"
            "-net nic,netdev=${x.id},model=virtio"
          ]) userInterfaces)

        # Audio configuration
        # --------------------------------------------
        # https://www.kraxel.org/blog/2020/01/qemu-sound-audiodev/
        # -device provides the sound card while -audiodev maps to the host's backend
        # 
        # Other notes:
        # -audiodev pipewire,id=snd0
        # -audio driver=pa,model=virtio,server=/run/user/1000/pulse/
        # -device intel-hda -device hda-output,audiodev=snd0
        # -device ich9-intel-hda -device hda-output,audiodev=snd0
        #
        # Displays
        # https://www.qemu.org/docs/master/system/qemu-manpage.html#hxtool-3
        # -display gtk
        # -display spice-app,gl=on
        ++ lib.optionals (cfg.audio) (
          if (cfg.spice.enable) then [
            # Mostly works, but tends to sputter some times
            "-audiodev spice,id=snd0"                     # SPICE as the host backend
            "-device virtio-sound-pci,audiodev=snd0"
          ] else [
            # Host display backend, gtk window with options
            #"-display gtk,gl=on,grab-on-hover=on,window-close=on,zoom-to-fit=on"
            #"-device virtio-gpu-gl"                       # Virtio OpenGL accelerated video card

            "-audiodev pipewire,id=snd0"                  # Pipewire as the host backend
            "-device virtio-sound-pci,audiodev=snd0"      # Virtio sound card
          ]
        )

        # Display configuration
        # ----------------------------------------------
        # Virglrenderer supported accelerated graphics
        ++ lib.optionals (cfg.display.enable) [
          "-vga none -device virtio-vga-gl"
          "-display sdl,gl=on"
        ]
        ++ lib.optionals (!cfg.display.enable) [
          "-nographic"
        ]

        # SPICE configuration
        # ----------------------------------------------
        # - working copy and past to and from the VM via remote-viewer
        # - https://www.qemu.org/docs/master/system/devices/virtio-gpu.html
        # https://www.kraxel.org/blog/2016/09/using-virtio-gpu-with-libvirt-and-spice/
        # - SPICE needs a unix socket connection for opengl to work
        # - glxgears --info
        # - glxinfo | grep virgl
        # - QXL defaults to 16 MB video memory, but needs 32MB min for high quality 
        # - QXL supports VGA, VGA BIOS, UEFI and has a kernel module
        # - -vga qxl vs -device qxl-vga
        # - Connect by launching `remote-viewer` and running `spice://localhost:5970`
        ++ lib.optionals (cfg.spice.enable) [
          "-vga qxl"
          "-device virtio-serial-pci"
          "-spice port=${toString cfg.spice.port},disable-ticketing=on"
          "-chardev spicevmc,id=${machine.hostname},debug=0,name=vdagent"
          "-device virtserialport,chardev=${machine.hostname},name=com.redhat.spice.0"
        ];
    })

    # Configure SPICE services on the Guest OS
    (lib.mkIf (machine.type.vm && cfg.spice.enable) {
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

    # Build the VM and create the startup/shutdown scripts
    (lib.mkIf (machine.type.vm) {
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
    })
  ];
}
