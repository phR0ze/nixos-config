# Incus configuration
#
# ### Features
# - purposefully renaming `virtualization` to give me a new namespace to work in
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.incus;
in
{
  options = {
    virtualization.incus = {
      enable = lib.mkEnableOption "Install and configure Incus";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Configure primary user permissions
    users.users.${args.username}.extraGroups = [ "incus-admin" ];

    # Enable and configure the app
    virtualisation.incus = {
      enable = true;
    };
  };
}
