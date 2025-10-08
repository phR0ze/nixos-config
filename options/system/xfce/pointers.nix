# XFCE Pointers options
#
# Generate the ~/.config/xfce/xfconf/xfce-perchannel-xml/pointers.xml configuration file
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, f, ... }: with lib.types;
let
  xfce = config.system.xfce;
  cfg = xfce.pointers;

  xmlfile = lib.mkIf (xfce.enable)
    (pkgs.writeText "pointers.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <channel name="pointers" version="1.0">
        <property name="VirtualBox_mouse_integration" type="empty">
          <property name="RightHanded" type="bool" value="${f.boolToStr cfg.rightHanded}"/>
          <property name="Threshold" type="int" value="4"/>
          <property name="Acceleration" type="double" value="${toString cfg.acceleration}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    system.xfce.pointers = {
      rightHanded = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable right handed";
      };
      acceleration = lib.mkOption {
        type = types.int;
        default = 8;
        description = lib.mdDoc "Mouse acceleration speed";
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfce.enable {
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/pointers.xml".copy = xmlfile;
  };

}
