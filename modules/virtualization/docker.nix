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

  users.users.${args.username} = {
    extraGroups = [ "docker" ];
  };
}
