# Import all the options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  xfce = config.system.xfce;
  machine = config.machine;
in 
{
  imports = [
    ./displays.nix
    ./keyboards.nix
    ./thunar.nix
    ./menu.nix
    ./panel.nix
    ./desktop.nix
    ./keyboard-shortcuts.nix
    ./power-manager.nix
    ./session.nix
    ./terminal.nix
    ./xfwm4.nix
    ./xsettings.nix
  ];

  options = {
    system.xfce = {
      enable = lib.mkEnableOption "Enable the Xfce desktop environment";
    };
  };
 
  config = lib.mkIf xfce.enable {

    # Nixpkgs provided options
    services = {
      displayManager = {
        defaultSession = "xfce";
      };
      xserver = {
        desktopManager.xfce = {
          enable = true;
          enableXfwm = true;                        # Enable X11 window manager
          enableScreensaver = true;
          #enableWaylandSession = true;             # Enable Wayland window manager
          #waylandSessionCompositor = "wayfire";    # Set the Wayland compositor
        };
        displayManager = {
          lightdm.background = xfce.desktop.background;
        };
      };
    };

    # Custom options
    # ----------------------------------------------------------------------------------------------
    system.x11.enable = true;

    system.xfce.panel.launchers = [
      { name = "WezTerm"; exec = "wezterm"; icon = "org.wezfurlong.wezterm"; }
      { name = "Thunar"; exec = "exo-open --launch FileManager"; icon = "org.xfce.thunar"; }
      {
        name = "Jellyfin";
        exec = "jellyfinmediaplayer";
        icon = "com.github.iwalton3.jellyfin-media-player";
      }
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

    # 1. Determine the desktop directory filename
    #    e.g `ll /run/current-system/sw/share/desktop-directories/xfce-network.directory`
    # 2. Add an override to change the desktop entry
    #    e.g. { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-network.directory"; name = "Network"; }
    system.xdg.menu.dirOverrides = [
      { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-network.directory"; name = "Network"; }
      { source = "${pkgs.xfce.garcon}/share/desktop-directories/xfce-accessories.directory"; icon = "applications-utilities"; }
    ];

    # 1. Determine the current app's desktop filename
    #    e.g `ll /run/current-system/sw/share/applications/xfce4-appfinder.desktop`
    # 2. Add an override to change the desktop entry
    #    e.g. { source = "${pkgs.xfce.xfce4-appfinder}/share/applications/xfce4-appfinder.desktop"; noDisplay = true; }
    system.xdg.menu.itemOverrides = [
      { source = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-web-browser.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-mail-reader.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-accessibility-settings.desktop"; noDisplay = true; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce-settings-manager.desktop"; noDisplay = true; }
      { source = "${pkgs.libreoffice}/share/applications/math.desktop"; categories = "Office"; }
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-file-manager.desktop"; icon = "Thunar"; }

      # By setting the category to X-Xfce-Toplevel
      { source = "${pkgs.wezterm}/share/applications/org.wezfurlong.wezterm.desktop"; categories = "X-Xfce-Toplevel"; }

      # By setting categories to Utility we've removed it from X-Xfce-Toplevel
      { source = "${pkgs.xfce.xfce4-settings}/share/applications/xfce4-terminal-emulator.desktop"; categories = "Utility"; }
    ];

    environment.xfce.excludePackages = with pkgs.xfce // pkgs; [
      tango-icon-theme                  # Xfce default,
      mousepad                          # Xfce default, simple text editor
      parole                            # Xfce default, simple media player
      ristretto                         # Xfce default, i like qview better
    ]
    # Conditionally include xfce4-appfinder if using an alternate app finder
    ++ lib.optional config.system.dmenu.enable xfce4-appfinder;
  };
}
