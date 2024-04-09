# XFCE options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./keyboards.nix
    ./menu.nix
    ./thunar.nix
    ./xsettings.nix
    ./xfce4-panel.nix
    ./xfce4-desktop.nix
    ./xfce4-power-manager.nix
  ];
}
