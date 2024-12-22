# XFCE terminal options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/xfce4-terminal.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.terminal;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  xmlfile = lib.mkIf xfceCfg.enable
    (pkgs.writeText "xfce4-terminal.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-terminal" version="1.0">
        <property name="misc-default-geometry" type="string" value="${cfg.defaultGeometry}"/>
        <property name="font-use-system" type="bool" value="${f.boolToStr cfg.fontUseSystem}"/>
        <property name="scrolling-lines" type="uint" value="${toString cfg.scrollingLines}"/>
        <property name="dropdown-keep-open-default" type="bool" value="${f.boolToStr cfg.dropDownKeepOpen}"/>
        <property name="dropdown-always-show-tabs" type="bool" value="${f.boolToStr cfg.dropDownShowTabs}"/>
        <property name="dropdown-status-icon" type="bool" value="${f.boolToStr cfg.dropDownStatusIcon}"/>
        <property name="dropdown-show-borders" type="bool" value="${f.boolToStr cfg.dropDownShowBorders}"/>
        <property name="dropdown-width" type="uint" value="${toString cfg.dropDownWidth}"/>
        <property name="dropdown-height" type="uint" value="${toString cfg.dropDownHeight}"/>
        <property name="dropdown-opacity" type="uint" value="${toString cfg.dropDownOpacity}"/>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.terminal = {
      scrollingLines = lib.mkOption {
        type = types.int;
        default = 10000;
        description = lib.mdDoc "Number of scrollback lines to preserve";
      };
      defaultGeometry = lib.mkOption {
        type = types.str;
        default = "130x50";
        description = lib.mdDoc "Default geometry to use for new windows";
      };
      fontUseSystem = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Use the system default mono font";
      };
      dropDownKeepOpen = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Keep drop down open when it looses focus";
      };
      dropDownShowTabs = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show tabs in the drop down terminal";
      };
      dropDownShowBorders = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show borders on the drop down terminal";
      };
      dropDownStatusIcon = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show drop down terminal status icon in the system tray";
      };
      dropDownWidth = lib.mkOption {
        type = types.int;
        default = 80;
        description = lib.mdDoc "Percentage of the screen width to use for drop down terminal";
      };
      dropDownHeight = lib.mkOption {
        type = types.int;
        default = 50;
        description = lib.mdDoc "Percentage of the screen height to use for drop down terminal";
      };
      dropDownOpacity = lib.mkOption {
        type = types.int;
        default = 100;
        description = lib.mdDoc "Percentage of opacity to use for drop down terminal";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfceCfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml".copy = xmlfile;
  };
}
