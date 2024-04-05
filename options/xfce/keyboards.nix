# XFCE Keyboard options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/keyboards.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.keyboards;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "keyboards.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="keyboards" version="1.0">
        <property name="Default" type="empty">
          <property name="Numlock" type="empty"/>
          <property name="KeyRepeat" type="empty">
            <property name="Rate" type="int" value="${toString cfg.repeat.rate}"/>
            <property name="Delay" type="int" value="${toString cfg.repeat.delay}"/>
          </property>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.keyboards = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable XFCE keyboards configuration";
      };
      ownConfigs = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Overwrite settings every reboot/update";
      };
    };
    services.xserver.desktopManager.xfce.keyboards.repeat = {
      delay = lib.mkOption {
        type = types.int;
        default = 203;
        description = lib.mdDoc "Keyboard repeat delay time";
      };
      rate = lib.mkOption {
        type = types.int;
        default = 102;
        description = lib.mdDoc "Keyboard repeat rate";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && !cfg.ownConfigs) {
      # Install manually crafted keyboard shortcuts
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".copy = 
        ../../include/home/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml;

      # Install the generated xml file
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml".copy = xmlfile;
    })
    (lib.mkIf (cfg.enable && cfg.ownConfigs) {
      # Install manually crafted keyboard shortcuts
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".ownCopy = 
        ../../include/home/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml;

      # Install the generated xml file
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml".ownCopy = xmlfile;
    })
  ];

}
