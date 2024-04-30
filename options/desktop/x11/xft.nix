# X11 xft options
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
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
}
