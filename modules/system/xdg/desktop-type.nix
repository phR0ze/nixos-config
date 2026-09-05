# Declares the desktop entry type for options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
{
  desktopType = submodule {
    options = {
      name = lib.mkOption {
        description = lib.mdDoc "Name of the desktop entry";
        type = types.str;
        default = "null";
      };
      exec = lib.mkOption {
        description = lib.mdDoc "Execution command for the desktop entry";
        type = types.str;
        default = "null";
      };
      icon = lib.mkOption {
        description = lib.mdDoc "Icon to use for the desktop entry";
        type = types.str;
        default = "null";
      };
      startupNotify = lib.mkOption {
        description = lib.mdDoc "Notify the user when the app starts";
        type = types.bool;
        default = false;
      };
      terminal = lib.mkOption {
        description = lib.mdDoc "Launch the execution command in a terminal window";
        type = types.bool;
        default = false;
      };
      noDisplay = lib.mkOption {
        description = lib.mdDoc "Hide this desktop entry from the menu";
        type = types.bool;
        default = false;
      };
      launcher = lib.mkOption {
        description = lib.mdDoc "Is this desktop entry a launcher";
        type = types.bool;
        default = false;
      };
      categories = lib.mkOption {
        description = lib.mdDoc "Category for the desktop entry";
        type = types.str;
        default = "null";
      };
      comment = lib.mkOption {
        description = lib.mdDoc "Comment for the desktop entry's tooltip";
        type = types.str;
        default = "null";
      };
      source = lib.mkOption {
        description = lib.mdDoc "Nix store path to the source desktop entry to start from";
        type = types.nullOr types.path;
        default = null;
      };
    };
  };
}
