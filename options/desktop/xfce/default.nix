# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.xserver.desktopManager.xfce;
  machine = config.machine;
in 
{
  imports = [
    ./displays.nix
    ./keyboards.nix
    ./thunar.nix
    ./menu.nix
    ./xfce4-panel.nix
    ./xfce4-desktop.nix
    ./xfce4-keyboard-shortcuts.nix
    ./xfce4-power-manager.nix
    ./xfce4-session.nix
    ./xfce4-terminal.nix
    ./xfwm4.nix
    ./xsettings.nix
  ];

  config = lib.mkIf cfg.enable {
    services = {
      displayManager = {
        defaultSession = "xfce";
      };
      xserver = {
        enable = true;
        displayManager = {
          lightdm.background = lib.mkOverride 900 "${pkgs.desktop-assets}/share/backgrounds/sector-8_1600x900.jpg";
        };
        desktopManager = {
          xfce.enableXfwm = true;
          xfce.enableScreensaver = true;
          xfce.desktop.background = lib.mkDefault "/run/current-system/sw/share/backgrounds/sector-8_1600x900.jpg";
          xfce.panel.launchers = [
            { name = "Alacritty"; exec = "alacritty"; icon = "Alacritty"; }
            { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
          ]
          ++
            lib.optional machine.type.theater { name = "Kodi"; exec = "kodi"; icon = "kodi"; }
          ++ [
            { name = "SMPlayer"; exec = "smplayer"; icon = "smplayer"; }
            { name = "HandBrake"; exec = "ghb"; icon = "fr.handbrake.ghb"; }
            { name = "VLC Media Player"; exec = "vlc"; icon = "vlc"; }
            { name = "FileZilla"; exec = "filezilla"; icon = "filezilla"; }
            { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
            { name = "LibreOffice Calc"; exec = "libreoffice --calc"; icon = "libreoffice-calc"; }
            { name = "LibreOffice Writer"; exec = "libreoffice --writer"; icon = "libreoffice-writer"; 
            }]
          ++
            lib.optional machine.type.develop { name = "Reboot"; exec = "sudo reboot"; icon = "system-reboot"; };
        };
      };
    };

    # 1. Determine the desktop directory filename
    #    e.g `ll /run/current-system/sw/share/desktop-directories/xfce-network.directory`
    # 2. Add an override to change the desktop entry
    #    e.g. { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-network.directory"; name = "Network"; }
    services.xdg.menu.dirOverrides = [
      { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-network.directory"; name = "Network"; }
      { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-accessories.directory"; icon = "applications-utilities"; }
    ];

    # 1. Determine the current app's desktop filename
    #    e.g `ll /run/current-system/sw/share/applications/xfce4-appfinder.desktop`
    # 2. Add an override to change the desktop entry
    #    e.g. { source = "${pkgs.xfce.xfce4-appfinder}/share/applications/xfce4-appfinder.desktop"; noDisplay = true; }
    services.xdg.menu.itemOverrides = [
      { source = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-web-browser.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-mail-reader.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-accessibility-settings.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce-settings-manager.desktop"; noDisplay = true; }
      { source = "${pkgs.libreoffice}/share/applications/math.desktop"; categories = "Office"; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-terminal-emulator.desktop"; name = "Terminal"; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-file-manager.desktop"; icon = "Thunar"; }
      { source = "${pkgs.veracrypt}/share/applications/veracrypt.desktop"; categories = "System"; }
      #{ source = "${pkgs.libsForQt5.qtstyleplugin-kvantum}/share/applications/kvantummanager.desktop"; categories = "Settings"; }
    ];

    environment.xfce.excludePackages = with pkgs.xfce // pkgs; [
      tango-icon-theme                  # Xfce default,
      mousepad                          # Xfce default, simple text editor
      parole                            # Xfce default, simple media player
      ristretto                         # Xfce default, i like qview better
    ]
    # Conditionally include xfce4-appfinder if using an alternate app finder
    ++ lib.optional config.programs.dmenu.enable xfce4-appfinder;

  };
}
