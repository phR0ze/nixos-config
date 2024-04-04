# XFCE X settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.xsettings;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "xsettings.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Net" type="empty">
          <property name="ThemeName" type="string" value="${cfg.gtk-theme}"/>
          <property name="IconThemeName" type="string" value="${cfg.icon-theme}"/>
          <property name="DoubleClickTime" type="empty"/>
          <property name="DoubleClickDistance" type="empty"/>
          <property name="DndDragThreshold" type="empty"/>
          <property name="CursorBlink" type="empty"/>
          <property name="CursorBlinkTime" type="empty"/>
          <property name="SoundThemeName" type="empty"/>
          <property name="EnableEventSounds" type="empty"/>
          <property name="EnableInputFeedbackSounds" type="empty"/>
        </property>
        <property name="Xft" type="empty">
          <property name="DPI" type="empty"/>
          <property name="Antialias" type="int" value="${toString (f.boolToInt cfg.font.anti-alias)}"/>
          <property name="Hinting" type="int" value="1"/>
          <property name="HintStyle" type="string" value="${cfg.font.hinting-style}"/>
          <property name="RGBA" type="empty"/>
        </property>
        <property name="Gtk" type="empty">
          <property name="CanChangeAccels" type="empty"/>
          <property name="ColorPalette" type="empty"/>
          <property name="FontName" type="empty"/>
          <property name="MonospaceFontName" type="string" value="${cfg.font.default-monospace}"/>
          <property name="IconSizes" type="empty"/>
          <property name="KeyThemeName" type="empty"/>
          <property name="ToolbarStyle" type="empty"/>
          <property name="ToolbarIconSize" type="empty"/>
          <property name="MenuImages" type="empty"/>
          <property name="ButtonImages" type="empty"/>
          <property name="MenuBarAccel" type="empty"/>
          <property name="CursorThemeName" type="empty"/>
          <property name="CursorThemeSize" type="empty"/>
          <property name="DecorationLayout" type="empty"/>
          <property name="DialogsUseHeader" type="empty"/>
          <property name="TitlebarMiddleClick" type="empty"/>
        </property>
        <property name="Gdk" type="empty">
          <property name="WindowScalingFactor" type="empty"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.xsettings = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable XFCE panel configuration";
      };
      gtk-theme = lib.mkOption {
        type = types.str;
        default = "Arc-Dark";
        description = lib.mdDoc "GTK theme";
      };
      icon-theme = lib.mkOption {
        type = types.str;
        default = "Paper";
        description = lib.mdDoc "Icon theme";
      };
    };
    services.xserver.desktopManager.xfce.xsettings.font = {
      default-monospace = lib.mkOption {
        type = types.str;
        default = "Inconsolata Nerd Font Mono 11";
        description = lib.mdDoc "Default monospace font";
      };
      anti-alias = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable font anti-aliasing";
      };
      hinting-style = lib.mkOption {
        type = types.str;
        default = "hintfull";
        description = lib.mdDoc "Font anti-aliasing hinting";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".copy = xmlfile;
  };
}