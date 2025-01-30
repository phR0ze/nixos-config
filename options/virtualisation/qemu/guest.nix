# QEMU guest configuration
#
# ### References:
# - [SPICE User manual](https://www.spice-space.org/spice-user-manual.html)
#---------------------------------------------------------------------------------------------------
{ modulesPath, config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  guest = config.virtualisation.qemu.guest;

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) guest.interfaces;
  userInterfaces = interfacesByType "user";
  macvtapInterfaces = interfacesByType "macvtap";
in
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
    ./macvtap.nix
    ./run.nix
  ];

  options = {
    virtualisation.qemu.guest = {
      enable = lib.mkEnableOption "Configure the VM's guest OS";
      cores = lib.mkOption {
        description = lib.mdDoc "Number of virtual cores for VM";
        type = types.int;
        default = 1;
      };
      diskSize = lib.mkOption {
        description = lib.mdDoc "Disk size in GB for VM";
        type = types.int;
        default = 1;
      };
      memorySize = lib.mkOption {
        description = lib.mdDoc "Memory size in GB for VM";
        type = types.int;
        default = 4;
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
      };
      audio = lib.mkOption {
        description = lib.mdDoc "Enable audio for VM";
        type = types.bool;
        default = false;
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
      services.qemuGuest.enable = true;             # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;   # We'll use SPICE instead

      # Virtual machine resource configuration
      # --------------------------------------------
      virtualisation = {
        diskSize = guest.diskSize * 1024;           # Configure disk size for the VM
        resolution = machine.resolution;            # Configure system resolution
        qemu.package = lib.mkForce pkgs.qemu_kvm;   # Ensure we have the standard KVM supported qemu

        # Allows for sftp, ssh etc... to the guest via localhost:2222
        #forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
      };

      virtualisation.qemu.options =
        # Networking configuration
        # --------------------------------------------
        # user: -net nic,netdev=vm-prod1,model=virtio -netdev user,id=vm-prod1
        # macvtap: -netdev tap,id=vm-prod1,fd=3 -device virtio-net-pci,netdev=vm-prod1,mac=02:00:00:00:00:01
        lib.optionals (macvtapInterfaces != [])
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
        ++ lib.optionals (guest.audio) (
          if (guest.spice.enable) then [
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
        ++ lib.optionals (guest.display.enable) [
          "-vga none -device virtio-vga-gl"
          "-display sdl,gl=on"
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
        ++ lib.optionals (guest.spice.enable) [
          "-vga qxl"
          "-device virtio-serial-pci"
          "-spice port=${toString guest.spice.port},disable-ticketing=on"
          "-chardev spicevmc,id=${machine.hostname},debug=0,name=vdagent"
          "-device virtserialport,chardev=${machine.hostname},name=com.redhat.spice.0"
        ];
    })

    # Configure SPICE services on the Guest OS
    (lib.mkIf (machine.type.vm && guest.spice.enable) {
      services.spice-autorandr.enable = true;       # Automatically adjust resolution of guest to spice client size
      services.spice-vdagentd.enable = true;        # SPICE agent to be run on the guest OS
      services.spice-webdavd.enable = true;         # Enable file sharing on guest to allow access from host

      # Install and configure higher performance display driver QXL for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];
      #services.xserver.videoDrivers = [ "virtio" ];
      #environment.systemPackages = [ pkgs.virglrenderer ];

      # Open up the firewall for machine.vm.spicePort
      networking.firewall.allowedTCPPorts = [ guest.spice.port ];
    })

    # Build the VM and create the startup/shutdown scripts
    (lib.mkIf (machine.type.vm) {
      system.build.vm = lib.mkForce (pkgs.runCommand "${machine.hostname}" { preferLocalBuild = true; } ''
        mkdir -p $out/bin
        ln -s ${config.system.build.toplevel} $out/system
        ln -s ${pkgs.writeScript "run-${machine.hostname}" guest.scripts.run} $out/bin/run

        # Optionally configure macvtap scripts
        if [[ "${if macvtapInterfaces != [] then "1" else "0"}" == "1" ]]; then
          ln -s ${pkgs.writeScript "macvtap-up" guest.scripts.macvtap-up} $out/bin/macvtap-up
          ln -s ${pkgs.writeScript "macvtap-down" guest.scripts.macvtap-down} $out/bin/macvtap-down
        fi
      '');
    })
  ];
}
