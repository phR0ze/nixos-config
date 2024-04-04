# XFCE Panel options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.xfce4-panel;

  # Define the xml file contents
  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "xfce4-panel.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-panel" version="1.0">
        <property name="configver" type="int" value="2"/>
        <property name="panels" type="array">
          <value type="int" value="1"/>
          <value type="int" value="2"/>
          <property name="dark-mode" type="bool" value="true"/>

          <!-- Taskbar components order -->
          <property name="panel-1" type="empty">
            <property name="position" type="string" value="p=8;x=0;y=0"/>
            <property name="length" type="double" value="100"/>
            <property name="position-locked" type="bool" value="true"/>
            <property name="icon-size" type="uint" value="${toString cfg.taskbar.icon-size}"/>
            <property name="size" type="uint" value="${toString cfg.taskbar.size}"/>
            <property name="plugin-ids" type="array">
              <value type="int" value="1"/>
              <value type="int" value="2"/>
              <value type="int" value="3"/>
              <value type="int" value="4"/>
              <value type="int" value="5"/>
              <value type="int" value="6"/>
              <value type="int" value="7"/>
              <value type="int" value="8"/>
              <value type="int" value="9"/>
              <value type="int" value="10"/>
              <value type="int" value="11"/>
              <value type="int" value="12"/>
            </property>
          </property>

          <!-- Launcher components order -->
          <property name="panel-2" type="empty">
            <property name="autohide-behavior" type="uint" value="1"/>
            <property name="position" type="string" value="p=9;x=0;y=0"/>
            <property name="length" type="double" value="1"/>
            <property name="position-locked" type="bool" value="true"/>
            <property name="size" type="uint" value="48"/>
            <property name="plugin-ids" type="array">
              ${lib.concatImapStringsSep "\n" (i: x: ''
                <value type="int" value="${toString (i + 20)}"/>'') cfg.launchers}
            </property>
          </property>
        </property>
        <property name="plugins" type="empty">

          <!-- Taskbar components -->
          <property name="plugin-1" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-2" type="string" value="applicationsmenu">
            <property name="show-button-title" type="bool" value="true"/>
            <property name="button-icon" type="string" value="${cfg.taskbar.icon}"/>
            <property name="button-title" type="string" value="${cfg.taskbar.title}"/>
          </property>
          <property name="plugin-3" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-4" type="string" value="tasklist">
            <property name="grouping" type="uint" value="1"/>
          </property>
          <property name="plugin-5" type="string" value="separator">
            <property name="expand" type="bool" value="true"/>
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-6" type="string" value="systray">
            <property name="square-icons" type="bool" value="true"/>
            <property name="known-legacy-items" type="array">
              <value type="string" value="xfce4-power-manager"/>
              <value type="string" value="ethernet network connection “wired connection 1” active"/>
            </property>
          </property>
          <property name="plugin-7" type="string" value="power-manager-plugin"/>
          <property name="plugin-8" type="string" value="notification-plugin"/>
          <property name="plugin-9" type="string" value="pulseaudio">
            <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
            <property name="show-notifications" type="bool" value="true"/>
          </property>
          <property name="plugin-10" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>
          <property name="plugin-11" type="string" value="clock">
            <property name="mode" type="uint" value="4"/>
            <property name="show-military" type="bool" value="${f.boolToStr cfg.clock.military}"/>
          </property>
          <property name="plugin-12" type="string" value="separator">
            <property name="style" type="uint" value="0"/>
          </property>

          <!-- Launcher components -->
          ${lib.concatImapStringsSep "\n" (i: x: ''
              <property name="plugin-${toString (i + 20)}" type="string" value="launcher">
                <property name="items" type="array">
                  <value type="string" value="${lib.toLower (lib.replaceStrings [" "] ["-"] x.name)}.desktop"/>
                </property>
            </property>'') cfg.launchers}
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
    services.xserver.desktopManager.xfce.xfce4-panel.taskbar = {
      title = lib.mkOption {
        type = types.str;
        default = "Apps";
        description = lib.mdDoc "Taskbar title";
      };
      icon = lib.mkOption {
        type = types.str;
        default = "cyberlinux";
        description = lib.mdDoc "Taskbar icon";
      };
      size = lib.mkOption {
        type = types.int;
        default = 24;
        description = lib.mdDoc "Taskbar size in pixels";
      };
      icon-size = lib.mkOption {
        type = types.int;
        default = 20;
        description = lib.mdDoc "Taskbar icon size in pixels";
      };
    };
    services.xserver.desktopManager.xfce.xfce4-panel.launchers = lib.mkOption {
      type = types.listOf (submodule {
        options = {
          name = lib.mkOption {
            type = types.str;
            description = lib.mdDoc "Name of the launcher";
          };
          exec = lib.mkOption {
            type = types.str;
            description = lib.mdDoc "Execution command for the launcher";
          };
          icon = lib.mkOption {
            type = types.str;
            description = lib.mdDoc "Icon to use for the launcher";
          };
          startup-notify = lib.mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc "Notify the user when the launcher starts";
          };
          terminal = lib.mkOption {
            type = types.bool;
            default = false;
            description = lib.mdDoc "Launch the execution command in a terminal window";
          };
          categories = lib.mkOption {
            type = types.str;
            default = "Utility;X-XFCE;X-Xfce-Toplevel;";
            description = lib.mdDoc "Category for the launcher";
          };
          comment = lib.mkOption {
            type = types.str;
            default = "Launch the given script or command";
            description = lib.mdDoc "Category for the launcher";
          };
        };
      });
      default = [];
      example = [
        { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
        { name = "terminal"; exec = "xfce4-terminal"; icon = "org.xfce.terminalemulator"; }
      ];
      description = lib.mdDoc "Define XFCE panel launchers";
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".copy = xmlfile;
  };
}
