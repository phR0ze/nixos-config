# XFCE desktop bundle: core + base + xfce/base + xfce/desktop
#
# ### Features
# - Directly installable: full general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../core.nix
    ../base.nix
    ../xfce/base.nix
    ../xfce/desktop.nix
  ];
}
