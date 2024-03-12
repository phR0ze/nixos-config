# Files configuration options
#
# ### Disclaimer
# This is NixOS specific and doesn't support other distributions or crossplatform systems. My intent 
# here is to provide some basic file manipulation for deploying configuration already stored in a git 
# repo. I specifically chose not to use Home Manager to keep this simple and avoid the complexity of 
# that solution.
#
# ### Details
# - provides the ability to install system files as root
# - provides the ability to install user files for target user as well as root
# - gets run on boot and on nixos-rebuild switch so be careful what is included here
# - files being deployed will overwrite the original files without any safe guards or checking
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
let
  #inherit (lib) stringAfter;

  # User files activation script using system.userActivationScript
  # ------------------------------------------------------------------------------------------------
  # - $HOME is available
  # - operation is run as the logged in user
  # - files and directories are owned by the logged in user
  userActivationScript = ''
    # Ensure xdg environment vars are set
    XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
    XDG_CACHE_HOME=''${XDG_CACHE_HOME:-$HOME/.cache}
    XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}
    XDG_STATE_HOME=''${XDG_STATE_HOME:-$HOME/.local/state}

    # Add startup applications?
    # cp -a ${../include/home/.config/autostart} ''${XDG_CONFIG_HOME}
    #ln -sf ${pkgs.something}/share/applications/something.desktop ''${XDG_CONFIG_HOME}/autostart
  '';

  # Files activation script using system.activationScript
  # ------------------------------------------------------------------------------------------------
  # - $HOME is not a valid value
  # - operation is run as the root user
  # - files and directories are owned by root by default
  activationScript = ''
    # Configure an immediate fail if something goes badly
    set -euo pipefail

#    makeFileEntry() {
#      src="$1"        # Source files to copy in
#      dest="$2"       # Destination path to deploy the file(s) to
#      mode="$3"       # Optional mode to use for the destination file(s)
#      user="$4"       # Optional user to use for the destination file(s)
#      group="$5"      # Optional group to use for the destination file(s)
#
#      # Globbing means the destination is a directory
#      if [[ "$src" = *'*'* ]]; then
#        exit 1 # not supported as of yet
#        mkdir -p "$out/$dest"                     # Create the destination directory
#        for fn in $src; do
#          ln -s "$fn" "$out/etc/$dest/"
#        done
#
#      # ?
#      else
#        mkdir -p "$out/$(dirname "$dest")"        # Create the destination directory
#        if ! [ -e "$out/$dest" ]; then
#          ln -s "$src" "$out/$dest"               # Link the source to the destination if it doesn't exist
#        else
#          echo "duplicate entry $dest -> $src"
#          if [ "$(readlink "$out/etc/$dest")" != "$src" ]; then
#            echo "mismatched duplicate entry $(readlink "$out/etc/$dest") <-> $src"
#            ret=1
#
#            continue
#          fi
#        fi
#
#        if [ "$mode" != symlink ]; then
#          echo "$mode" > "$out/etc/$dest.mode"
#          echo "$user" > "$out/etc/$dest.uid"
#          echo "$group" > "$out/etc/$dest.gid"
#        fi
#      fi
#    }
#
    # ----------------------------------------------------------------------------------------------
    # Ensure xdg environment vars are set
    #configs=/home/${args.settings.username}/.config

    #rm -rf ''${configs}/foobar
    #cp -a ${../include/home} ''${configs}/foobar
    #echo "this is a test 2" > ''${configs}/foobar

    # xdg-desktop-settings generates this empty file but
    #rm -fv ''${XDG_CONFIG_HOME}/menus/applications-merged/xdg-desktop-menu-dummy.menu

    #trolltech_conf="''${XDG_CONFIG_HOME}/Trolltech.conf"
    #if [ -e "$trolltech_conf" ]; then
    #  ${getBin pkgs.gnused}/bin/sed -i "$trolltech_conf" -e '/nix\\store\|nix\/store/ d'
    #fi
  '';
in
{
  options = {

    # files option
    # ----------------------------------------------------------------------------------------------
    files = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy in the target system.
        - destination paths must be absolute paths e.g. /root/foo
      '';
      type = with types; attrsOf (submodule (
        { name, config, options, ... }: {
          options = {
            dest = mkOption {
              type = types.str;
              description = lib.mdDoc "Absolute destination path. Defaults to the attribute name.";
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = lib.mdDoc "Text of the file.";
            };

            source = mkOption {
              type = types.path;
              description = lib.mdDoc "Path of the source file.";
            };
          };

          # config in this context will be the files."" definition
          config = {

            # Default the destination name to the attribute name
            dest = mkDefault name;

            # Create a nix store package out of the raw text if it exists
            # Generate a new nix store package name from the given name
            source = mkIf (config.text != null) (
              let name' = "files" + lib.replaceStrings ["/"] ["-"] name;
              in mkDerivedConfig options.text (pkgs.writeText name')
            );
          };
        }
      ));
    };
  };

  # Activation scripts
  # ----------------------------------------------------------------------------------------------
  # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/activation/activation-script.nix
  # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc-activation.nix

  config.system.activationScripts.files = stringAfter [ "etc" "users" "groups" ] activationScript;

  #config.system.userActivationScripts.files = userActivationScript;
}
