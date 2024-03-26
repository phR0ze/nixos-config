# Files root option
# Wraps the 'any' option to make all the paths relative to the '/root' path to simplify root user 
# configuration options.
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
    files.root = mkOption {
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

  # We are changing the user sets names to the unique target definitions set above to avoid 
  # clashing with values set in other options. Potentially we could be setting 
  # 'files.user.".dircolors"' and 'files.root.".dircolors"' or others. This gives them a unique 
  # name.
  #
  # e.g. error i was getting before changing the name to avoid conflicts
  #   error: The option `files.any.".dircolors".target' has conflicting definition values:
  #   - In `/nix/store/vcgagc2la95ngp00296x0ac69s9d0vmx-source/options/files/root.nix': "root/.dircolors"
  #   - In `/nix/store/vcgagc2la95ngp00296x0ac69s9d0vmx-source/options/files/user.nix': "home/admin/.dircolors"
  # ----------------------------------------------------------------------------------------------
  #config.files.any = mkMerge [
  #  (attrsets.mapAttrs' (name: value: nameValuePair (value.target) value) config.files.root)
  #];
}
