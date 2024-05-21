# XFCE Panel options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.panel;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  desktopType = (import ../desktop-type.nix {
    inherit options config lib pkgs args;
  }).desktopType;

  # Define the xml file contents
  panelXmlFile = lib.mkIf xfceCfg.enable
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
            <property name="icon-size" type="uint" value="${toString cfg.taskbar.iconSize}"/>
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
            <property name="size" type="uint" value="${toString cfg.launcher.size}"/>
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
            <property name="grouping" type="bool" value="${f.boolToStr cfg.taskbar.grouping}"/>
            <property name="sort-order" type="uint" value="4"/>
            <property name="window-scrolling" type="bool" value="false"/>
            <property name="show-handle" type="bool" value="false"/>
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

  # Generate launcher files based on the launcher options definitions
  launchersPackage = pkgs.runCommandLocal "launchers" {} ''
    set -euo pipefail             # Configure an immediate fail if something goes badly

    createLauncher() {
      local filename="$1"         # filename of the launcher
      local name="$2"             # filename of the launcher
      local exec="$3"             # execution command line for the launcher
      local icon="$4"             # icon string to use for the launcher
      local notify="$5"           # notify on startup bool
      local terminal="$6"         # enable a terminal window with the launcher
      local order="$7"            # order of the launcher

      # Launcher path used in final ~/.config/xfce4/panel/launcher-xx location
      local dir="$out/launcher-$order"
      local launcher="$dir/$filename.desktop"

      # Create the launcher
      mkdir -p "$dir"
      echo "[Desktop Entry]" > "$launcher"
      echo "Version=1.0" >> "$launcher"
      echo "Type=Application" >> "$launcher"
      echo "Exec=$exec" >> "$launcher"
      echo "Icon=$icon" >> "$launcher"
      echo "StartupNotify=$notify" >> "$launcher"
      echo "Terminal=$terminal" >> "$launcher"
      echo "Categories=Utility;X-XFCE;X-Xfce-Toplevel;" >> "$launcher"
      echo "OnlyShowIn=XFCE;" >> "$launcher"
      echo "X-AppStream-Ignore=True" >> "$launcher"
      echo "Name=$name" >> "$launcher"
      echo "Comment=" >> "$launcher"
    }

    # Create bash function calls to createLauncher for each launcher entry
    ${lib.concatImapStringsSep "\n" (i: x: lib.escapeShellArgs [
      "createLauncher"
      (lib.toLower (lib.replaceStrings [" "] ["-"] x.name))
      x.name
      x.exec
      x.icon
      (f.boolToStr x.startupNotify)
      (f.boolToStr x.terminal)
      (toString (i+20))
    ]) cfg.launchers}
  '';

in
{
  options = {
    services.xserver.desktopManager.xfce.panel.clock = {
      military = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable military time";
      };
    };
    services.xserver.desktopManager.xfce.panel.taskbar = {
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
        default = 24; # 36 for hidpi
        description = lib.mdDoc "Taskbar size in pixels";
      };
      iconSize = lib.mkOption {
        type = types.int;
        default = 20; # 32 for hidpi
        description = lib.mdDoc "Taskbar icon size in pixels";
      };
      grouping = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Taskbar item grouping";
      };
    };
    services.xserver.desktopManager.xfce.panel.launcher = {
      size = lib.mkOption {
        type = types.int;
        default = 36; # 52 for hidpi
        description = lib.mdDoc "Launcher size in pixels";
      };
    };
    services.xserver.desktopManager.xfce.panel.launchers = lib.mkOption {
      type = types.listOf desktopType;
      default = [];
      example = [
        { name = "Firefox"; exec = "firefox"; icon = "firefox"; }
        { name = "Xfce4 terminal"; exec = "xfce4-terminal"; icon = "org.xfce.terminalemulator"; }
      ];
      description = lib.mdDoc "Define XFCE panel launchers";
    };
  };

  # Install the generated xml file
  config = lib.mkMerge [
    (lib.mkIf xfceCfg.enable {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml".copy = panelXmlFile;
      files.all.".config/xfce4/panel".link = launchersPackage;
    })
  ];
}
