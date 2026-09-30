# Declares the desktop entry type for options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
{
  desktopType = submodule {
    options = {
      name = lib.mkOption {
        description = "Name of the desktop entry";
        type = types.str;
        default = "null";
      };
      exec = lib.mkOption {
        description = "Execution command for the desktop entry";
        type = types.str;
        default = "null";
      };
      icon = lib.mkOption {
        description = "Icon to use for the desktop entry";
        type = types.str;
        default = "null";
      };
      startupNotify = lib.mkOption {
        description = "Notify the user when the app starts";
        type = types.bool;
        default = false;
      };
      terminal = lib.mkOption {
        description = "Launch the execution command in a terminal window";
        type = types.bool;
        default = false;
      };
      noDisplay = lib.mkOption {
        description = "Hide this desktop entry from the menu";
        type = types.bool;
        default = false;
      };
      launcher = lib.mkOption {
        description = "Is this desktop entry a launcher";
        type = types.bool;
        default = false;
      };
      categories = lib.mkOption {
        description = "Category for the desktop entry";
        type = types.str;
        default = "null";
      };
      comment = lib.mkOption {
        description = "Comment for the desktop entry's tooltip";
        type = types.str;
        default = "null";
      };
      source = lib.mkOption {
        description = "Nix store path to the source desktop entry to start from";
        type = types.nullOr types.path;
        default = null;
      };
    };
  };
}
