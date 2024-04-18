# Display settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../funcs { inherit lib; };
  xfceCfg = config.services.xserver.desktopManager.xfce;
  cfg = xfceCfg.displays;

  xmlfile = lib.mkIf (xfceCfg.enable)
    (pkgs.writeText "displays.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="displays" version="1.0">
      ${lib.optionalString (cfg.resolution.x != 0 && cfg.resolution.y != 0) ''
        <property name="ActiveProfile" type="string" value="Default"/>
        <property name="Default" type="empty">
          <property name="Default" type="string" value="Default">
            <property name="Resolution" type="string" value="${toString cfg.resolution.x}x${toString cfg.resolution.y}"/>
          </property>
        </property>
      ''}
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
      resolution = {
        x = lib.mkOption {
          type = types.int;
          default = 0;
          description = lib.mdDoc "Horizontal resolution component";
        };
        y = lib.mkOption {
          type = types.int;
          default = 0;
          description = lib.mdDoc "Vertical resolution component";
        };
      };
    };
  };

  config = lib.mkMerge [

    # Set the xserver resolution if set
    (lib.mkIf (cfg.resolution.x != 0 && cfg.resolution.y != 0) {
      services.xserver.resolutions = [ { x = cfg.resolution.x; y = cfg.resolution.y; } ];
    })

    # Set the displays configuration file
    (lib.mkIf (xfceCfg.enable) {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/displays.xml".copy = xmlfile;
    })
  ];
}
