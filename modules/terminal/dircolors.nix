# Dircolors configuration
#---------------------------------------------------------------------------------------------------
#
# ### Features
# - using the universal dircolors from 
#   https://github.com/seebi/dircolors-solarized/blob/master/dircolors.ansi-universal
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
    extraConfig = builtins.readFile ./LS_COLORS;
  };
}

# vim:set ts=2:sw=2:sts=2
