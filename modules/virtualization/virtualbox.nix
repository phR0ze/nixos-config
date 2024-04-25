# Virtualbox configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualisation.virtualbox;

in
{
  config = lib.mkIf (cfg.host.enable) {
    # Causes a full lengthy compilation
    #virtualisation.virtualbox.host.enableExtensionPack = true;

    # Define the vboxnet0 network interface
    virtualisation.virtualbox.host.addNetworkInterface = true;

    # Add user to the vboxusers group
    users.extraGroups.vboxusers.members = [ args.settings.username ];
  };
}
