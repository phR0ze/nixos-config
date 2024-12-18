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

  # Generate systemd services for each enabled VM
  config.systemd = lib.mkMerge (lib.lists.forEach args.vms (x:
    (lib.mkIf x.enable {
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
    })
  ));
}
