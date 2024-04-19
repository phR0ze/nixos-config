# Files root option
# Wraps the 'any' option to make all the paths relative to the '/root' path to simplify root user 
# configuration options.
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
    files.root = lib.mkOption {
      default = {};
      description = lib.mdDoc ''
        Set of files to deploy to the root user's directory
        - destination paths must be relative to /root e.g. .config
      '';
      example = ''
        # Create a single file from raw text
        files.root.".dircolors".text = "this is a test";

        # Include a local file as your target
        files.root.".dircolors".copy = ../include/home/.dircolors;

        # Multi file example
        files.root = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
        };
      '';
      type = fileType "root" "root" "root/";
    };
  };
}
