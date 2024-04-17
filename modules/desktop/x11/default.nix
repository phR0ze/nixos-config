# X11 minimal configuration
#
# Clock format
# %a  Abbreviated weekday name (Mon, Tue, etc.)
# %A  Full weekday name (Monday, Tuesday, etc.)
# %b  Abbreviated month name (Jan, Feb, etc.)
# %B  Full month name (January, February, etc.)
# %d  Day of month
# %j  Julian day of year
# %m  Month number (01-12)
# %y  Year in century
# %Y  Year with 4 digits
# -------------------------------------------------------------------------------
# %H  Hour (00-23)
# %I  Hour (00-12)
# %M  Minutes (00-59)
# %S  Seconds(00-59)
# %P  AM or PM
# %p  am or pm
# -------------------------------------------------------------------------------
# %D  Date as %m/%d/%y
# %r  Time as %I:%M:%S %p
# %R  Time as %H:%M
# %T  Time as %H:%M:%S
# %Z  Time Zone Name 
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../funcs { inherit lib; };
  cfg = config.services.xserver;

in
{
  imports = [
    ../../terminal
    ../../hardware/audio.nix
    ../../hardware/bluetooth.nix
    ../../hardware/firmware.nix
    ../../hardware/printers.nix
    ../../hardware/video.nix
    ../../network/firefox.nix
    ../../network/network-manager.nix
    ../backgrounds/opt.nix
    ../fonts.nix
    ../icons.nix
    ../xdg.nix
  ];

  options = {
    services.xserver.xft = {
      gtkTheme = lib.mkOption {
        type = types.str;
        default = "Arc-Dark";
        description = lib.mdDoc "GTK theme";
      };
      qtTheme = lib.mkOption {
        type = types.str;
        default = "ArcDark";
        description = lib.mdDoc "Qt theme";
      };
      iconTheme = lib.mkOption {
        type = types.str;
        default = "Paper";
        description = lib.mdDoc "Icon theme";
      };
      cursorTheme = lib.mkOption {
        type = types.str;
        default = "Numix-Cursor-Light";
        description = lib.mdDoc "Cursor theme";
      };
      cursorSize = lib.mkOption {
        type = types.int;
        default = 16;
        description = lib.mdDoc "Cursor size";
      };
      sans = lib.mkOption {
        type = types.str;
        default = "DejaVu Sans Book";
        description = lib.mdDoc "Default sans font";
      };
      sansSize = lib.mkOption {
        type = types.int;
        default = 11;
        description = lib.mdDoc "Default sans font size";
      };
      serif = lib.mkOption {
        type = types.str;
        default = "DejaVu Serif Book";
        description = lib.mdDoc "Default serif font";
      };
      serifSize = lib.mkOption {
        type = types.int;
        default = 11;
        description = lib.mdDoc "Default serif font size";
      };
      monospace = lib.mkOption {
        type = types.str;
        default = "InconsolataGo Nerd Font Mono";
        description = lib.mdDoc "Default monospace font";
      };
      monospaceStyle = lib.mkOption {
        type = types.str;
        default = "Regular";
        description = lib.mdDoc "Default monospace font style";
      };
      monospaceSize = lib.mkOption {
        type = types.int;
        default = 13;
        description = lib.mdDoc "Default monospace font size";
      };
      dpi = lib.mkOption {
        type = types.int;
        default = 96;
        description = lib.mdDoc "Xft dpi";
      };
      rgba = lib.mkOption {
        type = types.str;
        default = "rgb";
        description = lib.mdDoc "Xft rgba";
      };
      antiAlias = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Xft anti-aliasing";
      };
      hintingStyle = lib.mkOption {
        type = types.str;
        default = "hintfull";
        description = lib.mdDoc "Xft anti-aliasing hinting";
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick = {
            enable = true;
            draw-user-backgrounds = true;
            theme.name = "Adwaita-dark";
            extraConfig = ''
              enable-hidpi=on
              show-a11y=false
              show-hostname=false
              show-keyboard=false
              clock-format=%a  %b  %d    %I:%M %P
            '';
          };
        };
        autoLogin.enable = args.settings.autologin;
        autoLogin.user = args.settings.username;
      };

      # Arch Linux recommends libinput and Xfce uses it in its settings manager
      libinput = {
        enable = true;
        mouse = {
          accelSpeed = "0.6";
        };
        touchpad = {
          accelSpeed = "1";
          naturalScrolling = true;
        };
      };
    };

    # Configure .Xresources
    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <${pkgs.writeText "Xresources" ''
        Xft.dpi: ${toString cfg.xft.dpi}
        Xft.rgba: ${cfg.xft.rgba}
        Xft.hinting: true
        Xft.antialias: ${f.boolToStr cfg.xft.antiAlias}
        Xft.hintstyle: ${cfg.xft.hintingStyle}
        Xft.lcdfilter: lcddefault
        XScreenSaver.dpmsEnabled: false

        *loginShell: true
        *saveLines: 65535

        *background: #1c1c1c
        *foreground: #d0d0d0
        *cursorColor: #ff5f00
        *cursorColor2: #000000

        *fontName: ${cfg.xft.monospace}:style=${cfg.xft.monospaceStyle}:size=${toString cfg.xft.monospaceSize}

        Xcursor.theme: ${cfg.xft.cursorTheme}
        Xcursor.size: ${toString cfg.xft.cursorSize}
      ''}
    '';

    # Disable power management stuff to avoid blanking
    environment.etc."X11/xorg.conf.d/20-dpms.conf".text = ''
      Section "Monitor"
          Identifier "Monitor0"
          Option     "DPMS" "0"
      EndSection
      Section "ServerLayout"
          Identifier "ServerLayout0"
          Option     "OffTime" "0"
          Option     "BlankTime" "0"
          Option     "StandbyTime" "0"
          Option     "SuspendTime" "0"
      EndSection
    '';

    programs.geany.enable = true;         # Simple text editor
    programs.filezilla.enable = true;     # Network/Transfer
    programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar
    programs.smplayer.enable = true;      # UI wrapper around mplayer with click to pause
    programs.xnviewmp.enable = true;      # Excellent image viewer

    services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
    services.gvfs.enable = true;          # GVfs virtual filesystem

    environment.systemPackages = with pkgs; [

      # Network

      # Media
      audacious                           # Lightweight advanced audio player
      audacious-plugins                   # Additional codecs support for audacious
      vlc                                 # Multi-platform MPEG, VCD/DVD, and DivX player

      # System
      desktop-file-utils                  # Command line utilities for working with desktop entries
      filelight                           # View disk usage information
  #    gnome-dconf-editor                 # General configuration manager that replaces gconf
      i3lock-color                        # Simple lightweight screen locker
      paprefs                             # Pulse audio server preferences for simultaneous output

      # Themes, icons and backgrounds
      arc-theme                           # Flat theme with transparent elements for GTK 3 and GTK 2
      arc-kde-theme                       # A port of the arc theme for Plasma
      paper-icon-theme                    # Modern icon theme designed around bold colors
      numix-cursor-theme                  # Numix cursor theme

      # Utilities
      galculator                          # Simple calculator
      alacritty                           # GPU accelerated terminal
      alacritty-theme                     # GPU accelerated terminal themes
    ];
  };
}
