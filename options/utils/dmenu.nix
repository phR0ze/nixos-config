# dmenu configuration
#
# ### Notes:
# - alterntive to the default xfce4-appfinder
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.dmenu;

  dmenuDesktopFilePackage = pkgs.runCommandLocal "dmenu" {} ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/dmenu.desktop <<EOF
    [Desktop Entry]
    Version=1.1
    Type=Application
    Name=Run...
    Icon=applications-other
    Exec=${cfg.run}
    Actions=
    Categories=X-XFCE;X-Xfce-Toplevel;
    EOF
  '';
in
{
  options = {
    programs.dmenu = {
      enable = lib.mkEnableOption "Install and configure dmenu";

      run = lib.mkOption {
        type = types.str;
        default = "dmenu_run -fn -misc-fixed-*-*-*-*-20-200-*-*-*-*-*-*  -i -nb '#000000' -nf '#efefef' -sf '#000000' -sb '#3cb0fd'";
        description = lib.mdDoc "Run command to use";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
      dmenu
      dmenuDesktopFilePackage
    ];

    # Trigger linking the package to the system path /run/current-system/sw 
    environment.pathsToLink = [
      "/share/applications"
    ];
  };
}
