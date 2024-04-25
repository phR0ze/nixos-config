# Virtualbox configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualisation.virtualbox;

in
{
  virtualisation.virtualbox = {
    #guest.enable = true;
    #guest.x11 = true;
    host.enable = true;
  };

  config = lib.mkIf (cfg.host.enable) {
    # Install the Oracle Extension Pack requiring allowUnfree
    virtualisation.virtualbox.host.enableExtensionPack = true;

    # Add user to the vboxusers group
    users.extraGroups.vboxusers.members = [ args.settings.username ];
  };
}
