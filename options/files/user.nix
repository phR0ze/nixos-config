# Files user option
# Wraps the 'any' option to make all the paths relative to the '/home/<user>' path to simplify user
# files configuration options.
#
# see ./any.nix for warnings and instructions
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
{
  options = {
    files.user = mkOption {
      description = lib.mdDoc ''
        Set of files to deploy to the user's home directory
        - destination paths must be relative to /home/<user> e.g. .config
      '';
      example = ''
        # Create a single file from raw text
        files.user.".dircolors".text = "this is a test";

        # Include a local file as your target
        files.user.".dircolors".copy = ../include/home/.dircolors;

        # Multi file example
        files.user = {
          ".config".copy = ../include/home/.config;
          ".dircolors".copy = ../include/home/.dircolors;
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
                files.user.".config".copy = ../include/home/.config;
                files.user.".dircolors".copy = ../include/home/.dircolors;
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
                files.user.".config".link = ../include/home/.config;
                files.user.".dircolors".link = ../include/home/.dircolors;
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
                the helper options 'copy', 'link', or 'text'.
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
              default = "${args.settings.username}";
              description = lib.mdDoc "Owner of file being created and/or the directories.";
            };

            group = mkOption {
              type = types.str;
              default = "users";
              description = lib.mdDoc "Group of file being created and/or the directories.";
            };
          };

          # config in this context will be the files.user."" definition
          config = {

            # Default the destination name to the attribute name
            target = mkDefault ("home/${args.settings.username}/" + name);

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

  # Merge the files.user options into files.any options
  # ----------------------------------------------------------------------------------------------
  config.files.any = mkMerge [
    (map (x: x // { name = x.target; } ) (attrValue config.files.user))
  ];
}
