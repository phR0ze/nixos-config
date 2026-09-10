# XFCE theater bundle: core + base + xfce/base + xfce/desktop + xfce/theater
#
# ### Features
# - Directly installable: desktop with additional media apps/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../console/core.nix
    ../console/base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
    ../xfce/theater.nix
  ];
}
