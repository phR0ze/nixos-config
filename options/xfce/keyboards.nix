# XFCE Keyboard options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/keyboard.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.keyboard;

  xmlfile = lib.mkIf (cfg.background != null)
    (pkgs.writeText "keyboard.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="keyboards" version="1.0">
        <property name="Default" type="empty">
          <property name="Numlock" type="${toString cfg.numlock}" value="true"/>
          <property name="KeyRepeat" type="empty">
            <property name="Delay" type="int" value="${toString cfg.repeat.delay}"/>
            <property name="Rate" type="int" value="${toString cfg.repeat.rate}"/>
          </property>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.keyboard = {
      numlock = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable numlock";
      };
    };
    services.xserver.desktopManager.xfce.keyboard.repeat = {
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
  config = lib.mkIf (cfg.background != null) {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/keyboard.xml".copy = xmlfile;
  };
}
