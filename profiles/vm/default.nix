# Lite VM configuration
# --------------------------------------------------------------------------------------------------
{ modulesPath, config, lib, pkgs, args, f, ... }:
let
  cfg = config.virtualization.virt-manager;
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")  # Imports a number of VM kernel modules
  ];

  config = lib.mkMerge [
    {
      # Guest machine overrides for virtual machine
      services.openssh.settings.PermitRootLogin = "yes";
      services.qemuGuest.enable = true;             # qemu guest support

      # Virtual machine configuration
      # - nixpkgs/nixos/modules/virtualisation/qemu-vm.nix
      virtualisation.vmVariant = {
        virtualisation = {
          cores = args.vm.cores;
          diskSize = args.vm.diskSize * 1024;
          memorySize = args.vm.memorySize * 1024;
          graphics = true;
          resolution = { x = args.vm.resolution.x; y = args.vm.resolution.y; };

          # Allows for sftp, ssh etc... to the guest via localhost:2222
          #forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
        };
      };
    }

    # Optionally enable SPICE support
    (lib.mkIf args.vm.spice {
      services.spice-vdagentd.enable = true;        # support SPICE clients
      services.spice-autorandr.enable = true;       # automatically adjust resolution to client size
      #services.spice-webdavd.enable = true;         # File sharing support between Host and Guest

      # Configure higher performance graphics for for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];

      # Configure SPICE
      virtualisation.vmVariant.virtualisation.qemu.options = [
        "-vga qxl"
        "-spice port=${toString args.vm.spicePort},disable-ticketing=on"
        "-device virtio-serial"
        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];
    })
  ];
}
