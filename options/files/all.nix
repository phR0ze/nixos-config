# Files all option
# Wraps the 'any' option to install the target file or directory for both the current user as well
# as for the root user.
#
# see ./any.nix for warnings and instructions
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }:
let

  # Import the shared fileType
  fileType = (import ./file-type.nix {
    inherit options config lib pkgs args;
  }).fileType;

in
{
  options = {
    files.all = lib.mkOption {
      default = {};
      description = lib.mdDoc ''
        Set of files to deploy to both the user's and root's home directories
        - destination paths must be relative to /home/<user> and /root e.g. .config
      '';
      example = ''
        # Create a single file from raw text
        files.all.".dircolors".text = "this is a test";

        # Include a local file as your target
        files.all.".dircolors".copy = ../include/home/.dircolors;

        # Multi file example
        files.all = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
        };
      '';
      type = fileType "${args.settings.username}" "users" "home/${args.settings.username}/";
    };
  };
}
