# Budgie desktop bundle: core + base + budgie/base
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../console/core.nix
    ../console/base.nix
    ../budgie/base.nix
  ];
}
