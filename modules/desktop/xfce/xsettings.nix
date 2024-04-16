# XFCE X settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.xsettings;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  xmlfile = lib.mkIf xfceCfg.enable
    (pkgs.writeText "xsettings.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Net" type="empty">
          <property name="ThemeName" type="string" value="${cfg.gtkTheme}"/>
          <property name="IconThemeName" type="string" value="${cfg.iconTheme}"/>
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
          <property name="Antialias" type="int" value="${toString (f.boolToInt cfg.font.antiAlias)}"/>
          <property name="Hinting" type="int" value="1"/>
          <property name="HintStyle" type="string" value="${cfg.font.hintingStyle}"/>
          <property name="RGBA" type="empty"/>
        </property>
        <property name="Gtk" type="empty">
          <property name="CanChangeAccels" type="empty"/>
          <property name="ColorPalette" type="empty"/>
          <property name="FontName" type="string" value="${cfg.font.defaultSans} ${toString cfg.font.defaultSansSize}"/>
          <property name="MonospaceFontName" type="string" value="${cfg.font.defaultMonospace} ${toString cfg.font.defaultMonospaceSize}"/>
          <property name="IconSizes" type="empty"/>
          <property name="KeyThemeName" type="empty"/>
          <property name="ToolbarStyle" type="empty"/>
          <property name="ToolbarIconSize" type="empty"/>
          <property name="MenuImages" type="empty"/>
          <property name="ButtonImages" type="empty"/>
          <property name="MenuBarAccel" type="empty"/>
          <property name="CursorThemeName" type="string" value="${cfg.cursorTheme}"/>
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
    };
    services.xserver.desktopManager.xfce.xsettings.font = {
      defaultSans = lib.mkOption {
        type = types.str;
        default = "DejaVu Sans Book";
        description = lib.mdDoc "Default sans font";
      };
      defaultSansSize = lib.mkOption {
        type = types.int;
        default = 11;
        description = lib.mdDoc "Default sans font size";
      };
      defaultMonospace = lib.mkOption {
        type = types.str;
        default = "DejaVu Sans Mono";
        description = lib.mdDoc "Default monospace font";
      };
      defaultMonospaceSize = lib.mkOption {
        type = types.int;
        default = 11;
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
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfceCfg.enable {

    # Add kvantum support to configure Qt theming to match
    environment.systemPackages = with pkgs; [
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
    ];

    # Configure the qt theme engine to use
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };

    # Configure the kvantum theme to use for Qt
    files.all.".config/Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${cfg.qtTheme}";
    #files.all.".config/Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";
    files.all.".config/Kvantum/ArcDark".link = ../../include/home/.config/Kvantum/ArcDark;
    files.all.".config/qt5ct/qt5ct.conf".text = ''
      [Fonts]
      fixed="${cfg.font.defaultMonospace},${toString cfg.font.defaultMonospaceSize},-1,5,50,0,0,0,0,0,Regular"
      general="${cfg.font.defaultSans},${toString cfg.font.defaultSansSize},-1,5,50,0,0,0,0,0,Regular"
    '';

    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".copy = xmlfile;
  };
}
