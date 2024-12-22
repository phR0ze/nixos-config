# Files all option
# Wraps the 'any' option to install the target file or directory for both the current user as well
# as for the root user.
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
    files.all = lib.mkOption {
      default = {};
      description = lib.mdDoc ''
        Set of files to deploy to both the user's and root's home directories
        - destination paths must be relative to /home/<user> and /root e.g. .config
      '';
      example = ''
        # Create a single file from raw text for both the root and current users
        files.all.".config/Kvantum/kvantum.kvconfig".text = "[General]\ntheme=ArkDark";

        # Include a local file as your target for both the root and current users
        files.all."root/.dircolors".copy = ../include/home/.dircolors;

        # Make a weak copy of the target file for both the root and current users
        files.all."root/.dircolors".weakCopy = ../include/home/.dircolors;

        # Existing nix store source path
        files.all.".config/Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";

        # Multi file example
        files.all = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
        };
      '';
      type = fileType "${machine.user.name}" "users" "home/${machine.user.name}/";
    };
  };
}
