# XFCE Power Manager options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.powerManager;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  xmlfile = lib.mkIf xfceCfg.enable
    (pkgs.writeText "xfce4-power-manager.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-power-manager" version="1.0">
        <property name="xfce4-power-manager" type="empty">
          <property name="show-tray-icon" type="bool" value="false"/>
          <property name="presentation-mode" type="bool" value="${f.boolToStr cfg.presentationMode}"/>
          <property name="power-button-action" type="uint" value="4"/>
          <property name="sleep-button-action" type="uint" value="1"/>
          <property name="hibernate-button-action" type="uint" value="2"/>
          <property name="battery-button-action" type="uint" value="1"/>
          <property name="dpms-enabled" type="bool" value="${f.boolToStr cfg.manageDisplayPower}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.powerManager = {
      presentationMode = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable presentation mode";
      };
      manageDisplayPower = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable xfce display power management i.e. dpms";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfceCfg.enable {
    powerManagement.enable = true;            # Indirectly installs xfce4-power-manager
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".copy = xmlfile;
  };
}
