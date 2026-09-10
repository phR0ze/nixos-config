# XFCE development bundle: core + base + xfce/base + xfce/desktop + xfce/develop
#
# ### Features
# - Directly installable: desktop with additional development tools/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../console/core.nix
    ../console/base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
    ../xfce/develop.nix
  ];
}
