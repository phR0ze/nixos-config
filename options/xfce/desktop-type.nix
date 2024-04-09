# Declares the desktop entry type for options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }:
{
  desktopType = submodule {
  type = types.listOf (submodule {
    options = {
      name = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Name of the desktop entry";
      };
      exec = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Execution command for the desktop entry";
      };
      icon = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Icon to use for the desktop entry";
      };
      startupNotify = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Notify the user when the app starts";
      };
      terminal = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Launch the execution command in a terminal window";
      };
      categories = lib.mkOption {
        type = types.str;
        default = "Utility;X-XFCE;X-Xfce-Toplevel;";
        description = lib.mdDoc "Category for the desktop entry";
      };
      comment = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Comment for the desktop entry's tooltip";
      };
    };
  };
}
