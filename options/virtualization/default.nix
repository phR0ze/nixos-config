# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }:
{
  imports = [
    ./incus.nix
    ./podman.nix
    ./virt-manager.nix
    ./winetricks.nix
  ];

  # Generate systemd services for each VM as directed
  config.systemd = lib.mkMerge (lib.lists.forEach args.vms (x:
    {
      services."vm-${x.hostname}" = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          KillSignal = "SIGINT";
          WorkingDirectory = "/var/lib/vm-${x.hostname}";
          ExecStart = "/var/lib/vm-${x.hostname}/result/bin/run-${x.hostname}-vm";
        };
      };
    }
  ));
#    (lib.mkIf (builtins.length args.vms > 0 && (builtins.elemAt args.vms 0).enable) (
}
