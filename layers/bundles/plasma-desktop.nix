# Plasma desktop bundle: core + base + plasma/base
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../core.nix
    ../base.nix
    ../plasma/base.nix
  ];
}
