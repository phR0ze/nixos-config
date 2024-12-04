# Podman configuration
#
# ### Features
# - purposefully renaming `virtualization` to give me a new namespace to work in
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.podman;

in
{
  options = {
    virtualization.podman = {
      enable = lib.mkEnableOption "Install and configure podman";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Allow primary user access to podman
    users.users.${args.settings.username}.extraGroups = [ "podman" ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true; # provide docker alias
      extraPackages = [
        pkgs.podman-compose
      ];

      # Allows docker containers to refer to each other by name
      defaultNetwork.settings.dns_enabled = true;

      # Removes dangling containers and images that are not being used. It won't remove any volumes by default
      autoPrune = {
        enable = true;
        dates = "weekly";

        # Removes stuff older than 24h and doesn't have the label important
        flags = [
          "--filter=until=24h"
          "--filter=label!=important"
        ];
      };
    };
  };
}
