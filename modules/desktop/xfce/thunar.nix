# XFCE Thunar options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../misc/funcs.nix { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.thunar;
  xfceCfg = config.services.xserver.desktopManager.xfce;

  thunarXmlfile = lib.mkIf xfceCfg.enable
    (pkgs.writeText "thunar.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar" version="1.0">
        <property name="last-view" type="string" value="${cfg.view}"/>
        <property name="last-show-hidden" type="bool" value="${f.boolToStr cfg.showHidden}"/>
      </channel>
    '');

  thunarVolmanXmlfile = lib.mkIf xfceCfg.enable
    (pkgs.writeText "thunar-volman.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="thunar-volman" version="1.0">
        <property name="automount-media" type="empty">
          <property name="enabled" type="bool" value="${f.boolToStr cfg.volman.automountMedia}"/>
        </property>
        <property name="automount-drives" type="empty">
          <property name="enabled" type="bool" value="${f.boolToStr cfg.volman.automountDrives}"/>
        </property>
      </channel>
    '');

in
{
  options = {
    services.xserver.desktopManager.xfce.thunar = {
      view = lib.mkOption {
        type = types.enum [ "ThunarDetailsView" ];
        default = "ThunarDetailsView";
        description = lib.mdDoc "The type of view to use";
      };
      showHidden = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Show hidden files and directories";
      };
    };
    services.xserver.desktopManager.xfce.thunar.volman = {
      automountMedia = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Mount removable media when inserted";
      };
      automountDrives = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Mount removable drives when hot-plugged";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf (xfceCfg.enable) {
    programs.thunar.enable = true;            # install and configure thunar
    programs.thunar.plugins = with pkgs.xfce; [
      thunar-volman                           # install volman plugin
      thunar-archive-plugin                   # install archive plugin
      thunar-media-tags-plugin                # install media tags plugin
    ];
    services.tumbler.enable = true;           # provides image thumbnails

    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml".copy = thunarXmlfile;
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml".copy = thunarVolmanXmlfile;
  };
}
