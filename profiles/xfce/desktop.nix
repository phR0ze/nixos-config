# XFCE full desktop configuration
#
# ### Features
# - Directly installable
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
  ];

  environment.systemPackages = with pkgs; [
  ];
}
