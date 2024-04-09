# Declares the desktop entry type for options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
{
  desktopType = submodule {
    options = {
      name = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Name of the desktop entry";
      };
      exec = lib.mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "Execution command for the desktop entry";
      };
      icon = lib.mkOption {
        type = types.str;
        default = "";
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
      noDisplay = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Hide this desktop entry from the menu";
      };
      launcher = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Is this desktop entry a launcher";
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
      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc "Nix store path to the source desktop entry to start from";
      };
    };
  };
}
