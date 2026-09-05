# Budgie desktop bundle: core + base + budgie/base
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../core.nix
    ../base.nix
    ../budgie/base.nix
  ];
}
