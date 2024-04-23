# XFCE Desktop options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.desktop;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  monitors = [
    "monitorDisplayPort-0"
    "monitorDisplayPort-1"
    "monitorDisplayPort-2"
    "monitorDP-0"
    "monitorDP-1"
    "monitorDP-2"

    # Variation seen on HP laptop
    "monitoreDP-0"
    "monitoreDP-1"
    "monitoreDP-2"

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
    "monitorLVDS-1"
    "monitorVGA-0"
    "monitorVGA-1"
    "monitorVirtual0"
    "monitorVirtual1"
    "monitorVirtual-0"
    "monitorVirtual-1"
  ];

  # Generate the xfce4-desktop xml settings file based on the given options
  # White space is a little tricky see docs link for more details
  # https://nixos.org/manual/nix/stable/language/values.html?highlight=indent#type-string
  xmlfile = lib.mkIf (xfceCfg.enable)
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
              </property>'') monitors}
          </property>
        </property>
        <property name="desktop-icons" type="empty">
          <property name="icon-size" type="uint" value="48"/>
          <property name="show-thumbnails" type="bool" value="true"/>
          <property name="file-icons" type="empty">
            <property name="show-home" type="bool" value="${f.boolToStr cfg.showHome}"/>
            <property name="show-trash" type="bool" value="${f.boolToStr cfg.showTrash}"/>
            <property name="show-filesystem" type="bool" value="${f.boolToStr cfg.showFilesystem}"/>
            <property name="show-removable" type="bool" value="${f.boolToStr cfg.showRemovable}"/>
          </property>
        </property>
        <property name="last" type="empty">
          <property name="window-width" type="int" value="${toString cfg.windowWidth}"/>
          <property name="window-height" type="int" value="${toString cfg.windowHeight}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.desktop = {
      background = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc "Desktop background";
      };
      showHome = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show home icon on desktop";
      };
      showTrash = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show trash icon on desktop";
      };
      showFilesystem = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show filesystem icon on desktop";
      };
      showRemovable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show removable drives icon on desktop";
      };
      windowWidth = lib.mkOption {
        type = types.int;
        default = 885;
        description = lib.mdDoc "Desktop settings window width";
      };
      windowHeight = lib.mkOption {
        type = types.int;
        default = 710;
        description = lib.mdDoc "Desktop settings window height";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfceCfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".copy = xmlfile;
  };
}
