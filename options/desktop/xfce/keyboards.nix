# XFCE Keyboard options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/keyboards.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.keyboards;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  xmlfile = lib.mkIf (xfceCfg.enable)
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
  config = lib.mkIf xfceCfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/keyboards.xml".copy = xmlfile;
  };
}
