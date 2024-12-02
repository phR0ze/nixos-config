# adguard home configuration
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.homelab.adguard;
in
{
  options = {
    homelab.adguard = {
      enable = lib.mkEnableOption "Configure and deploy Adguard Home";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    containers."adguard" = {
      config = { config, lib, pkgs, args, ... }: {
        # Configure base NixOS container
        system.stateVersion = args.settings.stateVersion;

        # Configure networking for Adguard Home
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [80];
        };

        # Configure Adguard Home
        services.adguardhome = {
          enable = true;
        };
      };
    };
  };
}
