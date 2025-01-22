# QEMU guest configuration
#
#---------------------------------------------------------------------------------------------------
{ modulesPath, config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  guest = config.virtualisation.qemu.guest;

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) guest.interfaces;
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
      spice = lib.mkOption {
        description = lib.mdDoc "Enable SPICE for VM";
        type = types.bool;
        default = true;
      };
      spicePort = lib.mkOption {
        description = lib.mdDoc "SPICE port for VM";
        type = types.int;
        default = 5970;
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
      interfaces = lib.mkOption {
        description = "Network interfaces";
        default = [];
        type = types.listOf (types.submodule {
          options = {
            type = lib.mkOption {
              type = types.enum [ "macvtap" ];
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
    };
  };

  config = lib.mkMerge [

    (lib.mkIf (machine.type.vm) {
      services.qemuGuest.enable = true;             # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;   # We'll use SPICE instead

      virtualisation = {
        resolution = machine.resolution;            # Configure system resolution
        qemu.package = lib.mkForce pkgs.qemu_kvm;  # Ensure we have the standard KVM supported qemu

        # Allows for sftp, ssh etc... to the guest via localhost:2222
        #forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
      };

      # Override and provide custom VM helper scripts
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

    # Optionally enable SPICE support
    # Connect by launching `remote-viewer` and running `spice://localhost:5970`
    (lib.mkIf (machine.type.vm && guest.spice) {

      # Configure QEMU for SPICE
      virtualisation.qemu.options = [
        "-vga qxl"
        "-spice port=${toString guest.spicePort},disable-ticketing=on"
        "-device virtio-serial"
        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];

      # Configure SPICE related services
      services.spice-vdagentd.enable = true;        # SPICE agent to be run on the guest OS
      services.spice-autorandr.enable = true;       # Automatically adjust resolution of guest to spice client size
      services.spice-webdavd.enable = true;         # Enable file sharing on guest to allow access from host

      # Configure higher performance graphics for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];

      # Open up the firewall for machine.vm.spicePort
      networking.firewall.allowedTCPPorts = [ guest.spicePort ];
    })
  ];
}
