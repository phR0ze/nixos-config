# Files user option
# Wraps the 'any' option to make all the paths relative to the '/home/<user>' path to simplify user
# files configuration options.
#
# see ./any.nix for warnings and instructions
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
let

  # Import the shared fileType
  fileType = (import ./file-type.nix {
    inherit options config lib pkgs args;
  }).fileType;

in
{
  options = {
    files.user = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy to the user's home directory
        - destination paths must be relative to /home/<user> e.g. .config
      '';
      example = ''
        # Create a single file from raw text
        files.user.".dircolors".text = "this is a test";

        # Include a local file as your target
        files.user.".dircolors".copy = ../include/home/.dircolors;

        # Multi file example
        files.user = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
        };
      '';
      type = fileType "${args.settings.username}" "users" "home/${args.settings.username}/";
    };
  };
}
