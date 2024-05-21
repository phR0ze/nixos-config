# X11 xft options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  xcfg = config.services.xserver;
  cfg = config.services.xserver.xft;

in
{
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
        default = "Noto Sans Regular";
        description = lib.mdDoc "Default sans serif font";
      };
      sansSize = lib.mkOption {
        type = types.int;
        default = 11;
        description = lib.mdDoc "Default sans serif font size";
      };
      serif = lib.mkOption {
        type = types.str;
        default = "Noto Serif Regular";
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

  config = lib.mkIf xcfg.enable {

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
