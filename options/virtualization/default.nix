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

  config = lib.mkMerge [
#    {
#      assertions = [
#        { assertion = (builtins.length vms == 2);
#          message = "Args length: ${toString (builtins.length vms)}"; }
#      ];
#    }

    # Create a systemd unit file for the first described VM
    (lib.mkIf (builtins.length args.vms > 0 && (builtins.elemAt args.vms 0).enable) (
      let
        vm = (builtins.elemAt args.vms 0);
      in
      {
        systemd.services."vm-${vm.hostname}" = {
          path = [ pkgs.util-linux ];
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];

          serviceConfig = {
            Type = "simple";
            KillSignal = "SIGINT";
            WorkingDirectory = "/var/lib/vm-${vm.hostname}";
            ExecStart = "/var/lib/vm-${vm.hostname}/result/bin/run-${vm.hostname}-vm";
          };
        };
      })
    )
  ];
}
