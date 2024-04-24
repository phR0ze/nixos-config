# XFCE session options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml configuration file
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  xfceCfg = config.services.xserver.desktopManager.xfce;
  cfg = xfceCfg.session;

  xmlfile = lib.mkIf (xfceCfg.enable)
    (pkgs.writeText "xfce-session.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-session" version="1.0">
        <property name="general" type="empty">
          <property name="SaveOnExit" type="bool" value="${f.boolToStr cfg.saveOnExit}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.desktop = {
      saveOnExit = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Save the open programs on exit and restore them on next session";
      };
    };
  };

  config = lib.mkIf (xfceCfg.enable) {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml".copy = xmlfile;
  };
}
