# XFCE Desktop options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver.desktopManager.xfce.xfce4-desktop;

in
{
  options = {
    services.xserver.desktopManager.xfce.xfce4-desktop = {
      background = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc "Set the XFCE desktop background.";
      };
    };
  };

  config = mkIf cfg.background {

    # Generate the xfce4-desktop xml settings file based on the given options
    xml = pkgs.runCommandLocal "xfce4-desktop-xml" {} ''
      set -euo pipefail             # Configure an immediate fail if something goes badly
      mkdir -p "$out"               # Creates the nix store path to populate

      target="$out/xfce4-desktop.xml"

      echo '<?xml version="1.0" encoding="UTF-8"?>' >> $target
      echo '${cfg.background}'
      echo '</channel>' >> $target
    '';

    # Install the generated xfce4-desktop xml file
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".copy = xml;
  };
}
