# Test VM configuration
#
# --------------------------------------------------------------------------------------------------
{ modulesPath, config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = lib.mkMerge [
    {
      machine.enable = true;
      services.openssh.settings.PermitRootLogin = "yes";

      # Virtual machine configuration
      # - nixpkgs/nixos/modules/virtualisation/qemu-vm.nix
      virtualisation.vmVariant = {
        virtualisation = {
          cores = cfg.vm.cores;
          diskSize = cfg.vm.diskSize;
          memorySize = cfg.vm.memorySize;
          graphics = cfg.vm.graphics;
          resolution = cfg.resolution;

          # Allows for sftp, ssh etc... to the guest via localhost:2222
          #forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
        };
      };
    }

    # Optionally enable SPICE support
    # Connect by launching `remote-viewer` and running `spice://localhost:5970`
    (lib.mkIf cfg.vm.spice {
      virtualisation.vmVariant.virtualisation.qemu.options = [
        "-vga qxl"
        "-spice port=${toString cfg.vm.spicePort},disable-ticketing=on"
        "-device virtio-serial"
        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];
    })
  ];
}
