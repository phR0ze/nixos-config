# All files option
# Install files to your system either as writable files or links to readonly nix store paths.
#
# ### Disclaimer
# This is NixOS specific and doesn't support other distributions or crossplatform systems. My intent 
# here is to provide some basic file manipulation for deploying configuration already stored in a git 
# repo. I specifically chose not to use Home Manager to keep this simple and avoid the complexity of 
# that solution.

# ### Warnings
# - gets run on boot and on nixos-rebuild switch so be careful what is included here
# - file type overwrites any existing target to keep the configuration accurage
# - removes owned files and directories when they are no longer in your configuration
# - multiple configurations for the same file or directory will be handled in a last out wins which
#   can be non-deterministic. best to not duplicate files or directory configurations for now.
#
# ### Features
# - pseudo atomic link switching via the /nix/files indirection link
# - merges with existing directories overwriting files that conflict but leaving unowned files
# - choose to install files as writable files or as links to readonly nix store paths
# - choose to own the files or directories, defaults to owning files and not owning directories
# - choose the mode, user, and group for files and or directories
# - only recreates links when they are incorrect or missing
# - supports spaces in file or directory names
#
# ### Implementation Details
# This option follows a similar pattern as the environment.etc option. The pattern consists of three 
# different components.
#  1. The option is defined here in this file
#  2. The option is imported into your project at the top level making it available everywhere
#  3. The option is invoked e.g. files.all."/root/foobar1".text = "this is a foobar1 test";
#  4. During nixos-rebuild switch the activationScripts get run performing the install
#  5. This in turn invokes the filesPackage via the reference
#  6. The files aggregate attribute set adds them to the /nix/store and links them in the parent package
#  7. The parent filesPackage package is then added to the /nix/store
#  8. Finally the original config.system.activationScripts.files payload is executed with the 
#     filesPackage as a parameter
#  9. The activation install script then uses the filesPackage to install the files
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
let

  # Filter the files calls down to just those that are enabled
  files' = filter (f: f.enable) (attrValues config.files.all);

  # Using runCommand to build a derivation that bundles the target files into a /nix/store package 
  # that we can then use during the activation later on to deploy the files to their indicated 
  # destination paths.
  # - $HOME is not a valid value
  # - operation is run as the root user
  # - files and directories are owned by root by default
  # ------------------------------------------------------------------------------------------------
  filesPackage = pkgs.runCommandLocal "files" {} ''
    set -euo pipefail             # Configure an immediate fail if something goes badly
    mkdir -p "$out"               # Creates the nix store path to populate

    track() {
      local src="$1"              # Source e.g. '/nix/store/23k9zbg0brggn9w40ybk05xw5r9hwyng-files-root-foobar'
      local dst="$2"              # Destination path to deploy to e.g. 'root/foobar'
      local kind="$3"             # Kind of file being created
      local dirmode="$4"          # Mode to use for directories
      local filemode="$5"         # Mode to use for files
      local user="$6"             # Owner to use for file and/or directories
      local group="$7"            # Group to use for file and/or directories
      local own="$8"              # Own the the file or directory
      local op="$9"               # Operation type

      # Validation on inputs
      [[ ''${dst:0:1} == "/" ]] && echo "paths must not start with a /" && exit 1
      [[ ''${dst:0-1} == "/" ]] && echo "paths must not end with a /" && exit 1
      [[ "$dst" == *".meta" ]] && echo "paths must not end with .meta" && exit 1

      echo "Linking: $src -> $out/$dst"

      # Determine meta name
      local meta
      if [[ -d "$src" ]]; then
        meta="$out/$dst.meta.dir"                       # craft meta file for directory
      else
        meta="$out/$dst.meta.file"                      # craft meta file name for files
      fi

      # Link nix store path
      local dir="$(dirname "$dst")"                     # grab the directory of the target
      [[ ''${dir} != "." ]] && mkdir -p "$out/$dir"     # create any needed directories
      ln -sf "$src" "$out/$dst"                         # link in the file content

      # Add the metadata file content
      echo "Metadata: $meta"
      echo "$op" >> "$meta"
      echo "$kind" >> "$meta"
      echo "$src" >> "$meta"
      echo "$dirmode" >> "$meta"
      echo "$filemode" >> "$meta"
      echo "$user" >> "$meta"
      echo "$group" >> "$meta"
      echo "$own" >> "$meta"
    }

    # Convert the files derivations into a list of calls to track by taking all the file
    # derivations escaping the arguments and adding them line by line to this ouput bash script.
    # e.g. 'track' '/nix/store/<hash>-files-root-foobar' '/root/foobar'
    ${concatMapStringsSep "\n" (entry: escapeShellArgs [
      "track"
      # Simply referencing the source file here will suck it into the /nix/store as its own package
      "${entry.source}"
      entry.target
      entry.kind
      entry.dirmode
      entry.filemode
      entry.user
      entry.group
      entry.own
      entry.op
    ]) files'}
  '';

  # Add the installer script to the /nix/store for reference
  # ------------------------------------------------------------------------------------------------
  installScript = pkgs.writeShellScript "installScript"
    (lib.fileContents ./install);
in
{
  options = {

    # all files option
    # ----------------------------------------------------------------------------------------------
    files.all = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy in the target system.
        - destination paths must be relative to the root e.g. etc/foo
        - various convenience options allow for setting a combination of other options
      '';
      example = ''
        # Create a single file from raw text
        files.all."root/.dircolors".text = "this is a test";

        # Include a local file as your target
        files.all."root/.dircolors".copy = ../include/home/.dircolors;

        # Include a local file as a readonly link
        files.all."root/.dircolors".link = ../include/home/.dircolors;

        # Multi file example
        files.all = {
          "etc/asound.conf".text = "autospawn=no";
          "root/.dircolors".copy = ../include/home/.dircolors;
          "etc/openal/alsoft.conf".link =  ../include/etc/openal/alsoft.conf;
        };
      '';

      type = with types; attrsOf (submodule (
        { name, config, options, ... }: {
          options = {

            enable = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc "Whether the source should be installed at the target path.";
            };

            target = mkOption {
              type = types.str;
              description = lib.mdDoc "Absolute destination path. Defaults to the attribute name.";
            };

            text = mkOption {
              default = null;
              type = types.nullOr types.lines;
              description = lib.mdDoc ''
                Raw text to be converted into a nix store object and then linked by default to the 
                indicated target path. To make this a file at the target location set 'kind="copy"'.
                - sets 'source' to the given file
                - sets 'kind' to 'link'
                - sets 'own' to 'default'
              '';
            };

            copy = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = ''
                files.all."root/.config".copy = ../include/home/.config;
                files.all."root/.dircolors".copy = ../include/home/.dircolors;
              '';
              description = lib.mdDoc ''
                Local file path or local directory path to install in system:
                - sets 'source' to the given file
                - sets 'kind' to 'copy'
                - sets 'own' to 'default'
              '';
            };

            link = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = ''
                files.all."root/.config".link = ../include/home/.config;
                files.all."root/.dircolors".link = ../include/home/.dircolors;
              '';
              description = lib.mdDoc ''
                Local file path or local directory path to install in system as a link:
                - sets 'source' to the given file or directory
                - sets 'kind' to 'link'
                - sets 'own' to 'default'
              '';
            };

            source = mkOption {
              type = types.path;
              example = "../include/home/.dircolors";
              description = lib.mdDoc ''
                Path of the local file to store or a pre-stored path. Prefer setting this value using 
                the helper options 'copy', 'dir', 'link', or 'text'.
                e.g. #1: ../include/home/.dircolors;
                e.g. #2: pkgs.writeText "root-.dircolors" (lib.fileContents ../include/home/.dircolors);
              '';
            };

            kind = mkOption {
              type = types.str;
              default = "link";
              description = lib.mdDoc ''
                Kind can be one of [ copy | link | dir ] and indicates the type of object being 
                created. When 'copy' is used the user, group and filemode properties will be used to 
                specify the file's properties and likewise user, group and dirmode for directories. 
                Similarly for 'link' dirmode, user, and group will set the directory properties of 
                any directories needing to be created for the link.
              '';
            };

            op = mkOption {
              type = types.str;
              default = "default";
              description = lib.mdDoc ''
                Operation can be one of [ default ]. Place holder for future.
              '';
            };

            own = mkOption {
              type = types.str;
              default = "default";
              description = lib.mdDoc ''
                Whether to own the file or directory or not. Possible values [ default | owned | free ].
                When a file or directory is owned it is automatically deleted if your 
                configuration not longer uses it. This can be dangerous if you have included a 
                directory such as .config in your home directory and set it as owned then remove your 
                dependency on it since it will remove the entire .config directory on clean up 
                despite other files you don't own being in the directory. This is why own is false 
                for directories by default and only true for files by default.
              '';
            };

            dirmode = mkOption {
              type = types.str;
              default = "0755";
              example = "0700";
              description = lib.mdDoc "Mode of any directories being created";
            };

            filemode = mkOption {
              type = types.str;
              default = "0644";
              example = "0777";
              description = lib.mdDoc "Mode of any files being created";
            };

            user = mkOption {
              type = types.str;
              default = "root";
              description = lib.mdDoc "Owner of file being created and/or the directories.";
            };

            group = mkOption {
              type = types.str;
              default = "root";
              description = lib.mdDoc "Group of file being created and/or the directories.";
            };
          };

          # config in this context will be the files.all."" definition
          config = {

            # Default the destination name to the attribute name
            target = mkDefault name;

            # Set kind based off the convenience options [ copy | link ]
            kind = if (config.link != null) then (mkForce "link")
              else mkForce "copy";

            # Set default for future use
            op = mkDefault "default";

            # Set default( i.e. files are owned and directories are not) but allows for user overrides
            own = mkDefault "default";

            # Set based off the convenience options
            source = if (config.copy != null) then (mkForce config.copy)
              else if (config.link != null) then (mkForce config.link)
              else mkIf (config.text != null) (mkDerivedConfig options.text (pkgs.writeText name));
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
  # By referencing the ${filesPackage} we trigger the derivation to be built and stored in 
  # the /nix/store which can then be used as an input variable for the actual deployment of files to 
  # their destination paths.
  config.system.activationScripts.files = stringAfter [ "etc" "users" "groups" ] ''
    ${installScript} ${filesPackage} "/nix"
  '';
}
