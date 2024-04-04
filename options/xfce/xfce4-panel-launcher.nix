# Declares xfce4 panel launcher type
#---------------------------------------------------------------------------------------------------
{ options, config, lib, ... }:
{
  xfce4PanelLauncherType = x: with lib.types; attrsOf (submodule (
    { name, config, options, ... }: {
      options = {

        target = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Name of the launcher";
        };

        order = lib.mkOption {
          type = types.int;
          description = lib.mdDoc "Order in which the launcher will appear";
        };

        exec = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Execution command for the launcher";
        };

        icon = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Icon to use for the launcher";
        };

        startup-notify = lib.mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Notify the user when the launcher starts";
        };

        terminal = lib.mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc "Launch the execution command in a terminal window";
        };

        categories = lib.mkOption {
          type = types.str;
          default = "Utility;X-XFCE;X-Xfce-Toplevel;";
          description = lib.mdDoc "Category for the launcher";
        };

        comment = lib.mkOption {
          type = types.str;
          default = "Launch the given script or command";
          description = lib.mdDoc "Category for the launcher";
        };
      };

      config = {

        # Default the target to the attribute name
        target = lib.mkDefault name;

        # Avoid clashing with the taskbar panel plugins by jumping up to 20
        order = config.order + 20; 
      };
    }
  ));
}
