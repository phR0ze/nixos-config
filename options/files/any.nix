# Files any option
# Install files to any path in your system either as writable files or links to readonly nix store 
# paths.
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
#  3. The option is invoked e.g. files.any."root/foobar1".text = "this is a foobar1 test";
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

  # Import the shared fileType
  fileType = (import ./file-type.nix {
    inherit options config lib pkgs args;
  }).fileType;

  # Filter the files.any calls down to just those that are enabled
  anyFiles = filter (f: f.enable) (attrValues config.files.any);

  # We are changing the user sets names to the unique target definitions set above to avoid 
  # clashing with values set in other options. Potentially we could be setting 
  # 'files.user.".dircolors"' and 'files.root.".dircolors"' or others. This gives them a unique 
  # name.
  #
  # e.g. error i was getting before changing the name to avoid conflicts
  #   error: The option `files.any.".dircolors".target' has conflicting definition values:
  #   - In `/nix/store/vcgagc2la95ngp00296x0ac69s9d0vmx-source/options/files/root.nix': "root/.dircolors"
  #   - In `/nix/store/vcgagc2la95ngp00296x0ac69s9d0vmx-source/options/files/user.nix': "home/admin/.dircolors"
  userFiles = if (config.files ? "user")
    then (attrsets.mapAttrs' (name: value: nameValuePair (value.target) value) config.files.user) else {};

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
    ]) anyFiles}
  '';

  # Add the installer script to the /nix/store for reference
  # ------------------------------------------------------------------------------------------------
  installScript = pkgs.writeShellScript "installScript"
    (lib.fileContents ./install);
in
{
  options = {

    # any files option
    # ----------------------------------------------------------------------------------------------
    files.any = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy in the target system.
        - destination paths must be relative to the root e.g. etc/foo
        - various convenience options allow for setting a combination of other options
      '';
      example = ''
        # Create a single file from raw text
        files.any."root/.dircolors".text = "this is a test";

        # Include a local file as your target
        files.any."root/.dircolors".copy = ../include/home/.dircolors;

        # Include a local file as a readonly link
        files.any."root/.dircolors".link = ../include/home/.dircolors;

        # Multi file example
        files.any = {
          "etc/asound.conf".text = "autospawn=no";
          "root/.dircolors".copy = ../include/home/.dircolors;
          "etc/openal/alsoft.conf".link =  ../include/etc/openal/alsoft.conf;
        };
      '';
      type = fileType "root" "root" "";
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
