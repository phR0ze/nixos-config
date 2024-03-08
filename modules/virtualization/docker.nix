# Docker configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  users.users.${args.settings.username} = {
    extraGroups = [ "docker" ];
  };
}
 
# vim:set ts=2:sw=2:sts=2
