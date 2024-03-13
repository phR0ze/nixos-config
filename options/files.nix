# Files option
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

  # Filter the files calls down to just those that are enabled
  files' = filter (f: f.enable) (attrValues config.files);

  # Using runCommand to build a derivation that bundles the target files into a /nix/store package 
  # that we can then use during the activation later on to deploy the files to their indicated 
  # destination paths.
  # - $HOME is not a valid value
  # - operation is run as the root user
  # - files and directories are owned by root by default
  # ------------------------------------------------------------------------------------------------
  filesActivationScript = pkgs.runCommandLocal "files" {} ''
    # Configure an immediate fail if something goes badly
    set -euo pipefail
    echo "setting up custom files"

    makeFileEntry() {
      src="$1"        # Source e.g. '/nix/store/23k9zbg0brggn9w40ybk05xw5r9hwyng-files-root-foobar'
      dest="$2"       # Destination path to deploy to e.g. '/root/foobar'

      # Trim off root slash if it exists
      [[ ''${dest:0:1} == "/" ]] && dest="''${dest:1}"

      # Link the source into the files derivation at the destination path
      mkdir -p "$out/$(dirname "$dest")"        # Create the destination directory
      ln -s "$src" "$out/$dest"

#      mkdir -p "$out/$(dirname "$dest")"        # Create the destination directory
#      if ! [ -e "$out/$dest" ]; then
#        ln -s "$src" "$out/$dest"               # Link the source to the destination if it doesn't exist
#      else
#        echo "duplicate entry $dest -> $src"
#        if [ "$(readlink "$out/etc/$dest")" != "$src" ]; then
#          echo "mismatched duplicate entry $(readlink "$out/etc/$dest") <-> $src"
#          ret=1
#
#          continue
#        fi
#      fi
    }

    # Convert the files derivations into a list of calls to makeFileEntry by taking all the files 
    # derivations escaping the arguments and adding them line by line to this ouput bash script.
    # e.g. 'makeFileEntry' '/nix/store/<hash>-files-root-foobar' '/root/foobar'
    mkdir -p "$out"
    ${concatMapStringsSep "\n" (entry: escapeShellArgs [
      "makeFileEntry"
      # Simply referencing the source file here will suck it into the /nix/store
      "${entry.source}"
      entry.dest
      #entry.mode
      #entry.user
      #entry.group
    ]) files'}
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

            enable = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc "Whether the file should be generated at the destination path.";
            };

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
  # - you can find the activation script in `ll -d /nix/store/*-nixos-system-nixos*/activate`
  # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/activation/activation-script.nix
  # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc-activation.nix

  # Adds a bash snippet to /nix/store/<hash>-nixos-system-nixos-24.05.20240229.1536926/activate.
  # By referencing the ${filesActivationScript} we trigger the derivation to be built and stored in 
  # the /nix/store which can then be used as an input variable for the actual deployment of files to 
  # their destination paths.
  config.system.activationScripts.files = stringAfter [ "etc" "users" "groups" ] ''
    echo "deploying files: ${filesActivationScript}"
  '';

  #config.system.userActivationScripts.files = userActivationScript;
}