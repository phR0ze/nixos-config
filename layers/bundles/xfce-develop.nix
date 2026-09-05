# XFCE development bundle: core + base + xfce/base + xfce/desktop + xfce/develop
#
# ### Features
# - Directly installable: desktop with additional development tools/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../core.nix
    ../base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
    ../xfce/develop.nix
  ];
}
