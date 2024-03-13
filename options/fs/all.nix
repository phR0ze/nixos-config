# All files option
#
# ### Disclaimer
# This is NixOS specific and doesn't support other distributions or crossplatform systems. My intent 
# here is to provide some basic file manipulation for deploying configuration already stored in a git 
# repo. I specifically chose not to use Home Manager to keep this simple and avoid the complexity of 
# that solution.
#
# ### Features
# - provides the ability to install system files as root
# - gets run on boot and on nixos-rebuild switch so be careful what is included here
# - files being deployed will overwrite the original files without any safe guards or checking
#
# ### Details
# This option follows a similar pattern as the environment.etc option. The pattern consists of three 
# different components.
#  1. The option is defined here in this file
#  2. The option is imported into your project at the top level making it available everywhere
#  3. The option is invoked e.g. files."/root/foobar1".text = "this is a foobar1 test";
#  4. During nixos-rebuild switch the activationScripts get run
#  5. The option's config.system.activationScripts.files configuration is invoked
#  6. This in turn invokes the allFilesActivationScript via the reference
#  7. The files aggregate attribute set adds them to the /nix/store and links them in the parent package
#  8. The parent allFilesActivationScript package is then added to the /nix/store
#  9. Finally the original config.system.activationScripts.files payload is executed with the 
#     allFilesActivationScript called 'allfiles' as a parameter
# 10. The activation script payload then uses the files package to install the files into your system
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
let

  # Filter the files calls down to just those that are enabled
  allfiles' = filter (f: f.enable) (attrValues config.fs.all);

  # Using runCommand to build a derivation that bundles the target files into a /nix/store package 
  # that we can then use during the activation later on to deploy the files to their indicated 
  # destination paths.
  # - $HOME is not a valid value
  # - operation is run as the root user
  # - files and directories are owned by root by default
  # ------------------------------------------------------------------------------------------------
  allFilesActivationScript = pkgs.runCommandLocal "files" {} ''
    set -euo pipefail # Configure an immediate fail if something goes badly
    mkdir -p "$out"   # Creates the root package directory

    linkfiles() {
      local src="$1"        # Source e.g. '/nix/store/23k9zbg0brggn9w40ybk05xw5r9hwyng-files-root-foobar'
      local dest="$2"       # Destination path to deploy to e.g. 'root/foobar'

      [[ ''${dest:0:1} == "/" ]] && exit 1  # Fail if the given destination path isn't relative
      local dir="$(dirname "/$dest")"       # Get the dir name

      # Create any directories that are needed
      [[ ''${dir} != "/" ]] && mkdir -p "$out/$dir"

      # Link the source into the files derivation at the destination path
      echo "Linking: $out/$dest -> $src"
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

    # Convert the files derivations into a list of calls to linkfiles by taking all the files 
    # derivations escaping the arguments and adding them line by line to this ouput bash script.
    # e.g. 'linkfiles' '/nix/store/<hash>-files-root-foobar' '/root/foobar'
    ${concatMapStringsSep "\n" (entry: escapeShellArgs [
      "linkfiles"
      # Simply referencing the source file here will suck it into the /nix/store
      "${entry.source}"
      entry.dest
      #entry.mode
      #entry.user
      #entry.group
    ]) allfiles'}
  '';
in
{
  options = {

    # all files option
    # ----------------------------------------------------------------------------------------------
    fs.all = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy in the target system.
        - destination paths must be relative to the root e.g. etc/foo
      '';
      example = ''
        # Single file example with inline content
        files."/root/.dircolors".text = "this is a test";

        # Single file example with source file content
        files."/root/.dircolors".source = ../include/home/.dircolors;

        # Single file example reading content from local file
        files."/root/.dircolors".text = builtins.readFile ../include/home/.dircolors;

        # Single file example with indirect source file
        files."/root/.dircolors".source = pkgs.writeText "root-.dircolors"
          (lib.fileContents ../include/home/.dircolors);

        # Multi file example
        files = {
          "/etc/asound.conf".text = "autospawn=no";

          "/root/.dircolors".source = pkgs.writeText "root-.dircolors"
            (lib.fileContents ../include/home/.dircolors);

          "/etc/openal/alsoft.conf".source = writeText "alsoft.conf" "drivers=pulse";
        };
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
              description = lib.mdDoc ''
                Path of the source file in the nix store e.g pkgs.writeText "root-.dircolors"
                  (lib.fileContents ../include/home/.dircolors);
              '';
            };
          };

          # config in this context will be the files."" definition
          config = {

            # Default the destination name to the attribute name
            dest = mkDefault name;

            # Create a nix store package out of the raw text if it's set
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
  # By referencing the ${allFilesActivationScript} we trigger the derivation to be built and stored in 
  # the /nix/store which can then be used as an input variable for the actual deployment of files to 
  # their destination paths.
  config.system.activationScripts.files = stringAfter [ "etc" "users" "groups" ] ''
    echo "deploying files: ${allFilesActivationScript}"
  '';
}
