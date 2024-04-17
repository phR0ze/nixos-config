# Font configuration
#
# ### Details
# - centralizing all font configuration here
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.defaultFonts;
  xCfg = config.services.xserver;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  # Build the package from the local files
  customFonts = pkgs.runCommandLocal "fonts" {} ''
    mkdir -p $out/share/doc/X11/fonts
    mkdir -p $out/share/X11/fonts
    cp -r ${../../include/usr/share/doc/TTF}/* $out/share/doc/X11/fonts
    cp -r ${../../include/usr/share/fonts/TTF}/* $out/share/X11/fonts
  '';
in
{
  options = {
    services.xserver.defaultFonts = {
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
      antiAlias = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable font anti-aliasing";
      };
      hintingStyle = lib.mkOption {
        type = types.str;
        default = "hintfull";
        description = lib.mdDoc "Font anti-aliasing hinting";
      };
      dpi = lib.mkOption {
        type = types.int;
        default = 96; # 192 ?
        description = lib.mdDoc "Font dpi";
      };
    };
  };

  config = lib.mkMerge [
    # Xfce font configuration
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf xfceCfg.enable {
      services.xserver.desktopManager.xfce.xsettings.font.defaultSans = cfg.sans;
      services.xserver.desktopManager.xfce.xsettings.font.defaultSansSize = cfg.sansSize;
      services.xserver.desktopManager.xfce.xsettings.font.defaultMonospace = cfg.monospace;
      services.xserver.desktopManager.xfce.xsettings.font.defaultMonospaceStyle = cfg.monospaceStyle;
      services.xserver.desktopManager.xfce.xsettings.font.defaultMonospaceSize = cfg.monospaceSize;
      services.xserver.desktopManager.xfce.xsettings.font.antiAlias = cfg.antiAlias;
      services.xserver.desktopManager.xfce.xsettings.font.hintingStyle = cfg.hintingStyle;
    })

    # X11 font configuration
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (xCfg.enable) {

      # Configure .Xresources
      services.xserver.displayManager.sessionCommands = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -merge <${pkgs.writeText "Xresources" ''
          Xft.dpi: ${toString cfg.dpi}
          Xft.rgba: rgb
          Xft.hinting: true
          Xft.antialias: ${f.boolToStr cfg.antiAlias}
          Xft.hintstyle: ${cfg.hintingStyle}
          Xft.lcdfilter: lcddefault
          XScreenSaver.dpmsEnabled: false

          *loginShell: true
          *saveLines: 65535

          *background: #1c1c1c
          *foreground: #d0d0d0
          *cursorColor: #ff5f00
          *cursorColor2: #000000

          *fontName: ${cfg.monospace}:style=${cfg.monospaceStyle}:size=${toString cfg.monospaceSize}

          Xcursor.theme: ${xfceCfg.xsettings.cursorTheme}
          Xcursor.size: ${toString xfceCfg.xsettings.cursorSize}
        ''}
      '';

      # Install font related packages and custom fonts
      environment.systemPackages = with pkgs; [
        customFonts               # Custom local fonts
        font-manager              # GTK font viewer
      ];

      environment.pathsToLink = [
        "/share/doc/X11/fonts"  # /run/current-system/sw/share/doc/X11/fonts
        "/share/X11/fonts"  # /run/current-system/sw/share/X11/fonts
      ];

      # Virtual console font will be chosen by the kernel
      # Default is 8x16 and Terminus 32 bold for larger resolutions
    #  console = {
    #    font = "ter-v24n";
    #    packages = with pkgs; [ terminus_font ];
    #  };

      fonts = {
        fontDir.enable = true;          # Create shared font dir /run/current-system/sw/share/X11/fonts

        fontconfig = {
          enable = true;                # Enable Fontconfig for X11 applications
          antialias = true;             # Enable font antialising
          hinting = {
            enable = true;              # Enable font hinting
            style = "slight";             # Configure slight hinting style
          };
          subpixel.rgba = "rgb";        # See option for more details
          defaultFonts.monospace = [
            "${cfg.monospace} ${cfg.monospaceStyle}"
            "DejaVu Sans Mono Book"
            "Hack Nerd Font Mono Regular"
            "Source Code Pro Regular"
          ];
          defaultFonts.sansSerif = [
            "${cfg.sans}"
            "Source Sans Pro Regular"
            "Liberation Sans Regular"
          ];
          defaultFonts.serif = [
            "${cfg.serif}"
            "Source Serif Pro Regular"
            "Liberation Serif Regular"
          ];
          #defaultFonts.emoji = [ "JoyPixels" ];
          localConf = ''
            <match>
              <test name="family"><string>Helvetica</string></test>
              <edit binding="same" mode="assign" name="family"><string>DejaVu Sans Book</string></edit>
            </match>
          '';
        };

        packages = with pkgs; [
          (nerdfonts.override {
            fonts = [
              "Hack"                    # Hand groomed/optically balanced typeface based on Bitstream Vera Mono
              "InconsolataGo"           # Best monospaced terminal font for coding
              "DroidSansMono"
            ];
          })
          corefonts                     # Microsoft's TrueType core fonts for the Web
          dejavu_fonts                  # A typeface family based on the Bitstream Vera fonts
          fira-code-nerdfont            # Mozilla foundation monospace font with programming ligatures
          font-awesome                  # Font Awesome OTF font
          inconsolata-nerdfont          # A monospace font for both screen and print
          liberation_ttf                # Font replacements for Times New Roman, Arial and Courier New
          ubuntu_font_family            # Ubuntu font family
          source-code-pro               # Monospaced font family for coding environments
          source-sans-pro               # Sans variant of source pro fonts
          source-serif-pro              # Serif variant of source pro fonts
          roboto-mono                   # Google Roboto Mono fonts
          roboto                        # Google Roboto family of fonts
          terminus-nerdfont             # A clean fixed width font
        ];
      };
    })
  ];
}
