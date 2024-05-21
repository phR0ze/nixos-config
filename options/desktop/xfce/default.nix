# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.xserver.desktopManager.xfce;
  backgrounds = pkgs.callPackage ../../../modules/desktop/backgrounds { };
  wmctl = pkgs.callPackage ../../../modules/desktop/wmctl { };

in 
{
  imports = [
    ./displays.nix
    ./keyboards.nix
    ./thunar.nix
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
    services.xserver = {
      enable = true;
      displayManager = {
        defaultSession = "xfce";
        # mkDefault is 1000 so this should take priority over defaults but allow for more overrides
        lightdm.background = lib.mkOverride 900 "${backgrounds}/share/backgrounds/sector-8_1600x900.jpg";
      };
      desktopManager = {
        xfce.enableXfwm = true;
        xfce.enableScreensaver = true;
        xfce.desktop.background = lib.mkDefault "/run/current-system/sw/share/backgrounds/sector-8_1600x900.jpg";
        xfce.panel.launchers = [
          { name = "Alacritty"; exec = "alacritty"; icon = "Alacritty"; }
          { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
          { name = "XnviewMP"; exec = "xnviewmp"; icon = "xnviewmp"; }
        ]
        ++
          lib.optional config.deployment.type.theater { name = "Kodi"; exec = "kodi"; icon = "kodi"; }
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
          lib.optional config.deployment.type.develop { name = "Reboot"; exec = "sudo reboot"; icon = "system-reboot"; };
      };
    };

    # 1. Determine the current app's desktop filename
    #    e.g `ll /run/current-system/sw/share/applications`
    #    e.g. xfce4-appfinder.desktop -> /nix/store/...-xfce4-appfinder-4.18.1/share/applications/xfce4-appfinder.desktop
    # 2. Add an override to change the desktop entry
    #    e.g. { source = "${pkgs.xfce.xfce4-appfinder}/share/applications/xfce4-appfinder.desktop"; noDisplay = true; }
    services.xdg.menu.overrides = [
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

    environment.systemPackages = with pkgs.xfce // pkgs; [
      wmctl
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
