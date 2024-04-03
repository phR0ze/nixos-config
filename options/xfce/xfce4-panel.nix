# XFCE Panel options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.xfce4-panel;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "xfce4-panel.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-panel" version="1.0">
        <property name="configver" type="int" value="2"/>
        <property name="panels" type="array">
          <value type="int" value="1"/>
          <value type="int" value="2"/>
          <property name="dark-mode" type="bool" value="true"/>
          <property name="panel-1" type="empty">
            <property name="position" type="string" value="p=8;x=0;y=0"/>
            <property name="length" type="double" value="100"/>
            <property name="position-locked" type="bool" value="true"/>
            <property name="icon-size" type="uint" value="16"/>
            <property name="size" type="uint" value="26"/>
            <property name="plugin-ids" type="array">
              <value type="int" value="1"/>
              <value type="int" value="2"/>
              <value type="int" value="3"/>
              <value type="int" value="5"/>
              <value type="int" value="6"/>
              <value type="int" value="9"/>
              <value type="int" value="10"/>
              <value type="int" value="8"/>
              <value type="int" value="11"/>
              <value type="int" value="12"/>
              <value type="int" value="13"/>
            </property>
          </property>
          <property name="panel-2" type="empty">
            <property name="autohide-behavior" type="uint" value="1"/>
            <property name="position" type="string" value="p=9;x=0;y=0"/>
            <property name="length" type="double" value="1"/>
            <property name="position-locked" type="bool" value="true"/>
            <property name="size" type="uint" value="48"/>
            <property name="plugin-ids" type="array">
              <value type="int" value="15"/>
              <value type="int" value="16"/>
              <value type="int" value="17"/>
              <value type="int" value="18"/>
              <value type="int" value="19"/>
              <value type="int" value="20"/>
              <value type="int" value="21"/>
              <value type="int" value="22"/>
            </property>
          </property>
        </property>
        <property name="plugins" type="empty">
          <property name="plugin-1" type="string" value="applicationsmenu">
            <property name="button-title" type="string" value=" Apps   "/>
          </property>
          <property name="plugin-2" type="string" value="tasklist">
            <property name="grouping" type="uint" value="1"/>
          </property>
          <property name="plugin-3" type="string" value="separator">
            <property name="expand" type="bool" value="true"/>
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-5" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-6" type="string" value="systray">
            <property name="square-icons" type="bool" value="true"/>
            <property name="known-legacy-items" type="array">
              <value type="string" value="xfce4-power-manager"/>
              <value type="string" value="ethernet network connection “wired connection 1” active"/>
            </property>
          </property>
          <property name="plugin-8" type="string" value="pulseaudio">
            <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
            <property name="show-notifications" type="bool" value="true"/>
          </property>
          <property name="plugin-9" type="string" value="power-manager-plugin"/>
          <property name="plugin-10" type="string" value="notification-plugin"/>
          <property name="plugin-11" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-12" type="string" value="clock">
            <property name="mode" type="uint" value="4"/>
            <property name="show-military" type="bool" value="${toString cfg.clock.military}"/>
          </property>
          <property name="plugin-13" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-15" type="string" value="showdesktop"/>
          <property name="plugin-16" type="string" value="separator"/>
          <property name="plugin-17" type="string" value="launcher">
            <property name="items" type="array">
              <value type="string" value="17120232521.desktop"/>
            </property>
          </property>
          <property name="plugin-18" type="string" value="launcher">
            <property name="items" type="array">
              <value type="string" value="17120232522.desktop"/>
            </property>
          </property>
          <property name="plugin-19" type="string" value="launcher">
            <property name="items" type="array">
              <value type="string" value="17120232523.desktop"/>
            </property>
          </property>
          <property name="plugin-20" type="string" value="launcher">
            <property name="items" type="array">
              <value type="string" value="17120232524.desktop"/>
            </property>
          </property>
          <property name="plugin-21" type="string" value="separator"/>
          <property name="plugin-22" type="string" value="directorymenu">
            <property name="base-directory" type="string" value="/home/admin"/>
          </property>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.xfce4-panel = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable XFCE panel configuration";
      };
    };
    services.xserver.desktopManager.xfce.xfce4-panel.clock = {
      military = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable military time";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".copy = xmlfile;
  };
}
