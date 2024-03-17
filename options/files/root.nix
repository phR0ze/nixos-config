# Root option
# Wraps the all option to make all the paths relative to the /root path to simplify root user 
# configuration options.
#
# see ./all.nix for warnings and instructions
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
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
          "root/.config".copyIn = ../include/home/.config;
          "root/.dircolors".copy = ../include/home/.dircolors;
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
                - sets 'kind' to link
                - sets 'own' to true
              '';
            };

            dir = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = "../include/home";
              description = lib.mdDoc ''
                Path to the local directory to install in system. This is a convenience option:
                - sets 'source' to the given directory
                - sets 'kind' to dir
                - sets 'own' to false
              '';
            };

            link = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = "../include/home/.dircolors";
              description = lib.mdDoc ''
                Path to the local file to install in system as a link. This is a convenience option:
                - sets 'source' to the given file
                - sets 'kind' to link
                - sets 'own' to true
              '';
            };

            linkIn = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = "../include/home/.dircolors";
              description = lib.mdDoc ''
                Local file path to link into the target or local directory path to link contents of 
                into the target. This is a convenience option to set the:
                - sets 'source' to the given file or directory
                - sets 'kind' to link
                - sets 'own' to true
                - sets 'op' to direct
              '';
            };

            copy = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = "../include/home/.dircolors";
              description = lib.mdDoc ''
                Path to the local file to install in system. This is a convenience option to set the:
                - sets 'source' to the given file
                - sets 'kind' to copy
                - sets 'own' to true
              '';
            };

            copyIn = mkOption {
              default = null;
              type = types.nullOr types.path;
              example = "../include/home/.dircolors";
              description = lib.mdDoc ''
                Local file path to copy into the target or local directory path to copy contents of 
                into the target. This is a convenience option to set the:
                - sets 'source' to the given file or directory
                - sets 'kind' to copy
                - sets 'own' to true
                - sets 'op' to direct
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
              example = "copy";
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
              description = lib.mdDoc ''
                Operation can be one of [ contents | direct ] and indicates the type of operation 
                being performed. Perfer setting this via the helper options: copyIn, linkIn.
                 - 'direct' means install the given file or directory at the given target path
                 - 'contents' means install the file or contents of directory into the given target
              '';
            };

            own = mkOption {
              type = types.bool;
              description = lib.mdDoc ''
                Whether to own the file or directory or not. When a file or directory is owned it is 
                automatically deleted if your configuration not longer uses it. This can be dangerous 
                if you have included a directory such as .config in your home directory and set it as 
                owned then remove your dependency on it since it will remove the entire .config 
                directory on clean up despite other files you don't own being in the directory. This 
                is why own is false for directories by default and only true for files by default.
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

          # config in this context will be the files."" definition
          config = {

            # Default the destination name to the attribute name
            target = mkDefault name;

            # Set kind based off the convenience options: file, link, dir, text
            kind = if (config.dir != null) then (mkForce "dir")
              else if (config.link != null) then (mkForce "link")
              else if (config.linkIn != null) then (mkForce "link")
              else if (config.copy != null) then (mkForce "copy")
              else mkIf (config.copyIn != null) (mkForce "copy");

            # Set based off the convenience options
            op = if (config.copyIn != null) then (mkForce "contents")
              else if (config.linkIn != null) then (mkForce "contents")
              else (mkForce "direct");

            # Set based off the convenience options
            own = if (config.copy != null) then (mkDefault true)
              else if (config.copyIn != null) then (mkDefault true)
              else if (config.link != null) then (mkDefault true)
              else if (config.linkIn != null) then (mkDefault true)
              else if (config.text != null) then (mkDefault true)
              else (mkDefault false);

            # Set based off the convenience options
            source = if (config.copy != null) then (mkForce config.copy)
              else if (config.copyIn != null) then (mkForce config.copyIn)
              else if (config.link != null) then (mkForce config.link)
              else if (config.linkIn != null) then (mkForce config.linkIn)
              else if (config.dir != null) then (mkForce config.dir)
              else mkIf (config.text != null) (mkForce (mkDerivedConfig options.text (pkgs.writeText name)));
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
