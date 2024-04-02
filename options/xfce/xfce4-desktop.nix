# XFCE Desktop options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.xfce4-desktop;

  # Generate the xfce4-desktop xml settings file based on the given options
  xmlfile = lib.mkIf (cfg.background != null)
    (pkgs.writeText "xfce4-desktop.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      ${cfg.background}
      </channel>
    '');

in
{
  options = {
    services.xserver.desktopManager.xfce.xfce4-desktop = {
      background = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc "Set the XFCE desktop background.";
      };
    };
  };

  config = lib.mkIf (cfg.background != null) {

    # Install the generated xfce4-desktop xml file
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".copy = xmlfile;
  };
}
