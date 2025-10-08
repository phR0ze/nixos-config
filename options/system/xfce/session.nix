# XFCE session options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml configuration file
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  xfce = config.system.xfce;
  cfg = xfce.session;

  xmlfile = lib.mkIf (xfce.enable)
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
    system.xfce.session = {
      saveOnExit = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Save the open programs on exit and restore them on next session";
      };
    };
  };

  config = lib.mkIf (xfce.enable) {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml".copy = xmlfile;
  };
}
