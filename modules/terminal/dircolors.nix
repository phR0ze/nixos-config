# Dircolors configuration
#---------------------------------------------------------------------------------------------------
# This is a home-manager module
# 
# ### Requirements
# - Required to be called from a home-manager context
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };
}

# vim:set ts=2:sw=2:sts=2
