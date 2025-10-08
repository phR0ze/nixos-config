# XFCE X settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, f, ... }: with lib.types;
let
  xfce = config.system.xfce;
  xft = config.system.x11.xft;

  xmlfile = lib.mkIf xfce.enable
    (pkgs.writeText "xsettings.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="Net" type="empty">
          <property name="ThemeName" type="string" value="${xft.gtkTheme}"/>
          <property name="IconThemeName" type="string" value="${xft.iconTheme}"/>
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
          <property name="DPI" type="int" value="${toString xft.dpi}"/>
          <property name="Antialias" type="int" value="${toString (f.boolToInt xft.antiAlias)}"/>
          <property name="Hinting" type="int" value="1"/>
          <property name="HintStyle" type="string" value="${xft.hintingStyle}"/>
          <property name="RGBA" type="string" value="${xft.rgba}"/>
        </property>
        <property name="Gtk" type="empty">
          <property name="CanChangeAccels" type="empty"/>
          <property name="ColorPalette" type="empty"/>
          <property name="FontName" type="string" value="${xft.sans} ${xft.sansStyle} ${toString xft.sansSize}"/>
          <property name="MonospaceFontName" type="string" value="${xft.monospace} ${xft.monospaceStyle} ${toString xft.monospaceSize}"/>
          <property name="IconSizes" type="empty"/>
          <property name="KeyThemeName" type="empty"/>
          <property name="ToolbarStyle" type="empty"/>
          <property name="ToolbarIconSize" type="empty"/>
          <property name="MenuImages" type="empty"/>
          <property name="ButtonImages" type="empty"/>
          <property name="MenuBarAccel" type="empty"/>
          <property name="CursorThemeName" type="string" value="${xft.cursorTheme}"/>
          <property name="CursorThemeSize" type="int" value="${toString xft.cursorSize}"/>
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
  # Install the generated xml file
  config = lib.mkIf xfce.enable {

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
    files.all.".config/Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${xft.qtTheme}";
    files.all.".config/Kvantum/ArcDark".link = ../../../include/home/.config/Kvantum/ArcDark;
    files.all.".config/qt5ct/qt5ct.conf".text = ''
      [Fonts]
      fixed="${xft.monospace},${toString xft.monospaceSize},-1,5,50,0,0,0,0,0,${xft.monospaceStyle}"
      general="${xft.sans},${toString xft.sansSize},-1,5,50,0,0,0,0,0,${xft.sansStyle}"
    '';

    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml".copy = xmlfile;
  };
}
