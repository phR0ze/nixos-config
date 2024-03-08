# XFCE full desktop configuration
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../x11/desktop.nix
  ];

  environment.systemPackages = with pkgs; [
  ];
}
