# XFCE minimal configuration
#
# ### Features
# - Directly installable: cli/default with bare minimal xfce environment
# - Size: 4504.7 MiB
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  backgrounds = pkgs.callPackage ../backgrounds { };
  wmctl = pkgs.callPackage ../wmctl { };
  xft = config.services.xserver.xft;

in
{
  imports = [
    ../x11
    ./xfwm4.nix
    ./displays.nix
    ./keyboards.nix
    ./menu.nix
    ./thunar.nix
    ./xsettings.nix
    ./xfce4-desktop.nix
    ./xfce4-keyboard-shortcuts.nix
    ./xfce4-panel.nix
    ./xfce4-power-manager.nix
    ./xfce4-session.nix
    ./xfce4-terminal.nix
  ];

  services.xserver = {
    displayManager = {
      defaultSession = "xfce";
      # mkDefault is 1000 so this should take priority over defaults but allow for more overrides
      lightdm.background = lib.mkOverride 900 "${backgrounds}/share/backgrounds/sector-8_1600x900.jpg";
    };
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xfce.enableScreensaver = true;
      xfce.desktop.background = lib.mkDefault "/run/current-system/sw/share/backgrounds/sector-8_1600x900.jpg";
      xfce.panel.launchers = [
        { name = "Xfce4 Terminal"; exec = "xfce4-terminal"; icon = "org.xfce.terminalemulator"; }
        { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
        { name = "XnviewMP"; exec = "xnviewmp"; icon = "xnviewmp"; }
      ]
      ++ lib.optional xft.theater { name = "Kodi"; exec = "kodi"; icon = "kodi"; }
      ++ [ { name = "SMPlayer"; exec = "smplayer"; icon = "smplayer"; }
        { name = "HandBrake"; exec = "ghb"; icon = "fr.handbrake.ghb"; }
        { name = "VLC Media Player"; exec = "vlc"; icon = "vlc"; }
        { name = "FileZilla"; exec = "filezilla"; icon = "filezilla"; }
        { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
        { name = "LibreOffice Calc"; exec = "libreoffice --calc"; icon = "libreoffice-calc"; }
        { name = "LibreOffice Writer"; exec = "libreoffice --writer"; icon = "libreoffice-writer"; }]
      ++ lib.optional virtualisation.host.enable { name = "VirtualBox"; exec = "VirtualBox"; icon = "virtualbox"; };

      xfce.menu.overrides = [
        { source = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop"; noDisplay = true; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-web-browser.desktop"; noDisplay = true; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-mail-reader.desktop"; noDisplay = true; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-accessibility-settings.desktop"; noDisplay = true; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce-settings-manager.desktop"; noDisplay = true; }
        { source = "${pkgs.libreoffice}/share/applications/math.desktop"; categories = "Office"; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-terminal-emulator.desktop"; name = "Terminal"; }
        { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-file-manager.desktop"; icon = "Thunar"; }
        { source = "${pkgs.neovim}/share/applications/nvim.desktop"; categories = "Development"; }
        { source = "${pkgs.veracrypt}/share/applications/veracrypt.desktop"; categories = "System"; }
        { source = "${pkgs.winetricks}/share/applications/winetricks.desktop"; categories = "System"; }
        { source = "${pkgs.protontricks}/share/applications/protontricks.desktop"; categories = "System"; }
        { source = "${pkgs.libsForQt5.qtstyleplugin-kvantum}/share/applications/kvantummanager.desktop"; categories = "Settings"; }
      ];
    };
  };

  environment.systemPackages = [
    wmctl
  ];

  environment.xfce.excludePackages = with pkgs.xfce // pkgs; [
    tango-icon-theme                  # Xfce default,
    mousepad                          # Xfce default, simple text editor
    parole                            # Xfce default, simple media player
  ];
}
