# Display settings options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.displays.resolution

  xmlfile = lib.mkIf (cfg.x != 0 && cfg.y != 0)
    (pkgs.writeText "xsettings.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xsettings" version="1.0">
        <property name="ActiveProfile" type="string" value="Default"/>
        <property name="Default" type="empty">
          <property name="Default" type="string" value="Default">
            <property name="Resolution" type="string" value="${toString cfg.x}x${toString cfg.y}"/>
          </property>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.displays.resolution = {
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

  config = lib.mkIf (cfg.x != 0 && cfg.y != 0) {

    # Set the xserver resolution
    services.xserver.resolutions = [ { x = cfg.x; y = cfg.y; } ];

    # Set the XFCE resolution
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/displays.xml".copy = xmlfile;
  };
}
