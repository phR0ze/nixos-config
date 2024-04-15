# XFCE development configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional development tools and configuration
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
  ];
}
