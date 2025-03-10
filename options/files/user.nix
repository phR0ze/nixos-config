# Files user option
# Wraps the 'any' option to make all the paths relative to the '/home/<user>' path to simplify user
# files configuration options.
#
# see ./any.nix for warnings and instructions
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }:
let
  machine = config.machine;

  # Import the shared fileType
  fileType = (import ./file-type.nix {
    inherit options config lib pkgs;
  }).fileType;

in
{
  options = {
    files.user = lib.mkOption {
      default = {};
      description = lib.mdDoc ''
        Set of files to deploy to the user's home directory
        - destination paths must be relative to /home/<user> e.g. .config
      '';
      example = ''
        # Create a single file from raw text for the current user
        files.user.".config/Kvantum/kvantum.kvconfig".text = "[General]\ntheme=ArkDark";

        # Include a local file as your target for the current user
        files.user."root/.dircolors".copy = ../include/home/.dircolors;

        # Make a weak copy of the target file for the current user
        files.user."root/.dircolors".weakCopy = ../include/home/.dircolors;

        # Existing nix store source path
        # Existing nix store source path
        files.user.".config/Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";

        # Multi file example
        files.user = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
        };
      '';
      type = fileType "${machine.user.name}" "users" "home/${machine.user.name}/";
    };
  };
}
