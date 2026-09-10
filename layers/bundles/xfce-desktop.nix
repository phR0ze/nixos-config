# XFCE desktop bundle: core + base + xfce/base + xfce/desktop
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../console/core.nix
    ../console/base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
  ];
}
