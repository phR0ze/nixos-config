# XFCE development configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional development tools and configuration
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./desktop.nix
    ../x11/develop.nix
  ];
}
