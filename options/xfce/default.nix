# XFCE options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./xfwm4.nix
    ./displays.nix
    ./keyboards.nix
    ./menu.nix
    ./thunar.nix
    ./xsettings.nix
    ./xfce4-panel.nix
    ./xfce4-desktop.nix
    ./xfce4-power-manager.nix
    ./xfce4-terminal.nix
  ];
}
