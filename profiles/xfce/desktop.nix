# XFCE full desktop configuration
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ../../modules/desktop/xfce
    ../../modules/desktop/x11/desktop.nix
  ];

  environment.systemPackages = with pkgs; [ ];
}
