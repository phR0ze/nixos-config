# Theater configuration for beelink-s12-pro
#
# ### Features
# - Directly installable: xfce/theater with additional hardware configuration
# --------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  imports = [
    ../../profiles/xfce/theater.nix
  ];

  # Add additional theater package
  environment.systemPackages = with pkgs; [ ];
}
