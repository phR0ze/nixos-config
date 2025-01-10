# Display settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml configuration file
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  xfceCfg = config.services.xserver.desktopManager.xfce;
  resolution = config.machine.resolution;
  cfg = xfceCfg.displays;

  xmlfile = lib.mkIf (xfceCfg.enable)
    (pkgs.writeText "displays.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="displays" version="1.0">
        ${lib.optionalString (resolution.x != 0 && resolution.y != 0) ''
          <property name="ActiveProfile" type="string" value="Default"/>
          <property name="Default" type="empty">
            <property name="Default" type="string" value="Default">
              <property name="Resolution" type="string" value="${toString resolution.x}x${toString resolution.y}"/>
            </property>
          </property>''}
        <property name="Notify" type="int" value="${toString cfg.connectingDisplay}"/>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.displays = {
      connectingDisplay = lib.mkOption {
        type = types.int;
        default = 1;
        description = lib.mdDoc ''
          Action to take when a display is connected.
          0 = Do nothing
          1 = Show dialog
          2 = Mirror
          3 = Extend
        '';
      };
    };
  };

  config = lib.mkMerge [

    # Set the xserver resolution if set
    (lib.mkIf (resolution.x != 0 && resolution.y != 0) {
      services.xserver.resolutions = [ resolution ];
    })

    # Set the displays configuration file
    (lib.mkIf (xfceCfg.enable) {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/displays.xml".copy = xmlfile;
    })
  ];
}
