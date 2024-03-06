# Virtualbox configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  virtualisation.virtualbox = {

    # Guest configuration
    guest.enable = true;
    guest.x11 = true;

    # Host configuration
    host.enable = true;
    host.enableExtensionPack = true;
  };

  # Add user to the vboxusers group
  users.extraGroups.vboxusers.members = [ args.settings.username ];
}
 
# vim:set ts=2:sw=2:sts=2
