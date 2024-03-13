# Files option
#
# ### Disclaimer
# This is NixOS specific and doesn't support other distributions or crossplatform systems. My intent 
# here is to provide some basic file manipulation for deploying configuration already stored in a git 
# repo. I specifically chose not to use Home Manager to keep this simple and avoid the complexity of 
# that solution.
#
# ### Features
# - provides the ability to install system files as root
# - provides the ability to install user files for target user as well as root
# - gets run on boot and on nixos-rebuild switch so be careful what is included here
# - files being deployed will overwrite the original files without any safe guards or checking
#---------------------------------------------------------------------------------------------------
{ options, lib, ... }: with lib;
{
  options = {
    fs = mkOption {
      default = {};
    };
  };
}
