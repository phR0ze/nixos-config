# XFCE laptop bundle: core + base + xfce/base + xfce/desktop + xfce/laptop
#
# ### Features
# - Directly installable: desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../console/core.nix
    ../console/base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
    ../xfce/laptop.nix
  ];
}
