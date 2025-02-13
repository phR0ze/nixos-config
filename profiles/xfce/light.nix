# XFCE minimal desktop configuration
#
# ### Features
# - Directly installable: minimal general purpose desktop environment
# --------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
let
  machine = config.machine;
in
{
  imports = [
    ../xorg.nix
  ];

  # Enable XFCE and all needed components
  services.xserver.desktopManager.xfce.enable = true;

  # Enable services
  services.raw.rustdesk.enable = true;    # Simple fast remote desktop solution

  environment.systemPackages = with pkgs; [
    #git                           # Fast distributed version control system
  ];
}
