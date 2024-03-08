# XFCE theater configuration
#
# ### Features
# - Directly installable
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  # The first element is used as the default resolution
  services.xserver.resolutions = [
    { x = 1920; y = 1080; }
  ];

  environment.systemPackages = with pkgs; [
  ];
}
