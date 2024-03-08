# XFCE full desktop configuration
#
# ### Features
# - Directly installable
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
