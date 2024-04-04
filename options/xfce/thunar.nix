# XFCE Thunar options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.thunar;

  thunarXmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "thunar.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar" version="1.0">
        <property name="last-view" type="string" value="${cfg.view}"/>
        <property name="last-show-hidden" type="bool" value="${f.boolToStr cfg.show-hidden}"/>
      </channel>
    '');

  thunarVolmanXmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "thunar-volman.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar-volman" version="1.0">
        <property name="automount-media" type="empty">
          <property name="enabled" type="bool" value="${f.boolToStr cfg.volman.automount-media}"/>
        </property>
        <property name="automount-drives" type="empty">
          <property name="enabled" type="bool" value="${f.boolToStr cfg.volman.automount-drives}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.thunar = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable XFCE thunar configuration";
      };
      view = lib.mkOption {
        type = types.enum = [ "ThunarDetailsView" ];
        default = "ThunarDetailsView";
        description = lib.mdDoc "The type of view to use";
      };
      show-hidden = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Show hidden files and directories";
      };
    };
    services.xserver.desktopManager.xfce.thunar.volman = {
      automount-media = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Mount removable media when inserted";
      };
      automount-drives = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Mount removable drives when hot-plugged";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf cfg.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".copy = thunarXmlfile;
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".copy = thunarVolmanXmlfile;
  };
}
