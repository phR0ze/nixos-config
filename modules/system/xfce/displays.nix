# Display settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml configuration file
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  xfce = config.system.xfce;
  cfg = xfce.displays;

  xmlfile = lib.mkIf (xfce.enable)
    (pkgs.writeText "displays.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="displays" version="1.0">
        ${lib.optionalString (xfce.resolution.x != 0 && xfce.resolution.y != 0) ''
          <property name="ActiveProfile" type="string" value="Default"/>
          <property name="Default" type="empty">
            <property name="Default" type="string" value="Default">
              <property name="Resolution" type="string" value="${toString xfce.resolution.x}x${toString xfce.resolution.y}"/>
            </property>
          </property>''}
        <property name="Notify" type="int" value="${toString cfg.connectingDisplay}"/>
      </channel>
    '');
in
{
  options = {
    system.xfce.displays = {
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
    (lib.mkIf (xfce.resolution.x != 0 && xfce.resolution.y != 0) {
      services.xserver.resolutions = [ xfce.resolution ];
    })

    # Set the displays configuration file
    (lib.mkIf (xfce.enable) {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/displays.xml".copy = xmlfile;
    })
  ];
}
