# XFCE terminal options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/xfce4-terminal.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.terminal;

  xmlfile = lib.mkIf cfg.enable
    (pkgs.writeText "xfce4-terminal.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="xfce4-terminal" version="1.0">
        <property name="dropdown-keep-open-default" type="bool" value="${f.boolToStr cfg.dropDownKeepOpen}"/>
        <property name="dropdown-always-show-tabs" type="bool" value="${f.boolToStr cfg.dropDownShowTabs}"/>
      </channel>
    '');
in
{
  options = {
    services.xserver.desktopManager.xfce.terminal = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable XFCE terminal configuration";
      };
      ownConfigs = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Overwrite settings every reboot/update";
      };
      dropDownKeepOpen = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Keep drop down open when it looses focus";
      };
      dropDownShowTabs = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Show tabs in the drop down terminal";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && !cfg.ownConfigs) {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml".copy = xmlfile;
    })
    (lib.mkIf (cfg.enable && cfg.ownConfigs) {
      files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml".ownCopy = xmlfile;
    })
  ];
}
