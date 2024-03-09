# Firefox configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    firefox
  ];
}
