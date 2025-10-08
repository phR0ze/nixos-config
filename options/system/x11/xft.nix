# X11 xft options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  x11 = config.system.x11;
  cfg = x11.xft;

in
{
  options = {
    system.x11.xft = {
      gtkTheme = lib.mkOption {
        description = lib.mdDoc "GTK theme";
        type = types.str;
        default = "Arc-Dark";
      };
      qtTheme = lib.mkOption {
        description = lib.mdDoc "Qt theme";
        type = types.str;
        default = "ArcDark";
      };
      iconTheme = lib.mkOption {
        description = lib.mdDoc "Icon theme";
        type = types.str;
        default = "Paper";
      };
      cursorTheme = lib.mkOption {
        description = lib.mdDoc "Cursor theme";
        type = types.str;
        default = "Numix-Cursor-Light";
      };
      cursorSize = lib.mkOption {
        description = lib.mdDoc "Cursor size";
        type = types.int;
        default = 16;
      };
      sans = lib.mkOption {
        description = lib.mdDoc "Default sans serif font";
        type = types.str;
        default = "Noto Sans";
      };
      sansStyle = lib.mkOption {
        description = lib.mdDoc "Default sans serif font style";
        type = types.str;
        default = "Regular";
      };
      sansSize = lib.mkOption {
        description = lib.mdDoc "Default sans serif font size";
        type = types.int;
        default = 11;
      };
      serif = lib.mkOption {
        description = lib.mdDoc "Default serif font";
        type = types.str;
        default = "Noto Serif";
      };
      serifStyle = lib.mkOption {
        description = lib.mdDoc "Default serif font style";
        type = types.str;
        default = "Regular";
      };
      serifSize = lib.mkOption {
        description = lib.mdDoc "Default serif font size";
        type = types.int;
        default = 11;
      };
      serifWebSize = lib.mkOption {
        description = lib.mdDoc "Default serif font size for Browser use";
        type = types.int;
        default = 16;
      };
      monospace = lib.mkOption {
        description = lib.mdDoc "Default monospace font";
        type = types.str;
        default = "InconsolataGo Nerd Font Mono";
      };
      monospaceStyle = lib.mkOption {
        description = lib.mdDoc "Default monospace font style";
        type = types.str;
        default = "Regular";
      };
      monospaceSize = lib.mkOption {
        description = lib.mdDoc "Default monospace font size";
        type = types.int;
        default = 13;
      };
      dpi = lib.mkOption {
        description = lib.mdDoc "Xft dpi";
        type = types.int;
        default = 96;
      };
      rgba = lib.mkOption {
        description = lib.mdDoc "Xft rgba";
        type = types.str;
        default = "rgb";
      };
      antiAlias = lib.mkOption {
        description = lib.mdDoc "Xft anti-aliasing";
        type = types.bool;
        default = true;
      };
      hintingStyle = lib.mkOption {
        description = lib.mdDoc "Xft anti-aliasing hinting";
        type = types.str;
        default = "hintfull";
      };
    };
  };

  config = lib.mkIf x11.enable {

    # Configure .Xresources
    services.xserver.displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <${pkgs.writeText "Xresources" ''
        Xft.dpi: ${toString cfg.dpi}
        Xft.rgba: ${cfg.rgba}
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

        Xcursor.theme: ${cfg.cursorTheme}
        Xcursor.size: ${toString cfg.cursorSize}
      ''}
    '';
  };
}
