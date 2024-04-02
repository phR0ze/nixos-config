# XFCE Desktop options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.xfce4-desktop;

  monitors = [
    "monitorDisplayPort-0"
    "monitorDisplayPort-1"
    "monitorDisplayPort-2"
    "monitorDP-0"
    "monitorDP-1"
    "monitorDP-2"
    "monitorDVI-0"
    "monitorDVI-1"
    "monitorDVI-2"
    "monitorDVI-D-0"
    "monitorDVI-D-1"
    "monitorDVI-D-2"
    "monitorDVI-I-0"
    "monitorDVI-I-1"
    "monitorDVI-I-2"
    "monitorHDMI0"
    "monitorHDMI1"
    "monitorHDMI2"
    "monitorHDMI-0"
    "monitorHDMI-1"
    "monitorHDMI-2"
    "monitorHDMI-A-0"
    "monitorHDMI-A-1"
    "monitorLVDS0"
    "monitorLVDS1"
    "monitorVGA-0"
    "monitorVGA-1"
    "monitorVirtual0"
    "monitorVirtual1"
    "monitorVirtual-0"
    "monitorVirtual-1"
  ];

  # Generate the xfce4-desktop xml settings file based on the given options
  xmlfile = lib.mkIf (cfg.background != null)
    (pkgs.writeText "xfce4-desktop.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>

      <channel name="xfce4-desktop" version="1.0">

        <property name="backdrop" type="empty">
          <property name="screen0" type="empty">
            ${lib.concatMapStringsSep "\n" (x: ''
            <property name="${x}" type="empty">
              <property name="workspace0" type="empty">
                <property name="color-style" type="int" value="0"/>
                <property name="image-style" type="int" value="5"/>
                <property name="last-image" type="string" value="${cfg.background}"/>
              </property>
            </property>
            '') monitors}
          </property>
        </property>

        <property name="desktop-icons" type="empty">
          <property name="icon-size" type="uint" value="48"/>
          <property name="show-thumbnails" type="bool" value="true"/>
          <property name="file-icons" type="empty">
            <property name="show-home" type="bool" value="false"/>
            <property name="show-trash" type="bool" value="false"/>
            <property name="show-filesystem" type="bool" value="false"/>
            <property name="show-removable" type="bool" value="false"/>
          </property>
        </property>

      </channel>
    '');

in
{
  options = {
    services.xserver.desktopManager.xfce.xfce4-desktop = {
      background = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc "Set the XFCE desktop background.";
      };
    };
  };

  config = lib.mkIf (cfg.background != null) {

    # Install the generated xfce4-desktop xml file
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".copy = xmlfile;
  };
}
