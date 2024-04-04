# Declares files fileType for use in various files options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }:
{
  # Constructs a files type.
  #
  # Arguments:
  #   - user          user to use as default for ownership e.g. "admin"
  #   - group         group to use as default for ownership e.g. "users"
  #   - prefix        path prefix including trailing slash to keep instances unique e.g. "root/" | "home/admin/"
  fileType = user: group: prefix: with lib.types; attrsOf (submodule (
    { name, config, options, ... }: {
      options = {

        enable = lib.mkOption {
          type = types.bool;
          default = true;
          description = lib.mdDoc "Whether the source should be installed at the target path.";
        };

        target = lib.mkOption {
          type = types.str;
          description = lib.mdDoc "Absolute destination path. Defaults to the attribute name.";
        };

        text = lib.mkOption {
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

        copy = lib.mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Local file path or local directory path to install in system:
            - sets 'source' to the given file
            - sets 'kind' to 'copy'
            - sets 'own' to 'default'
          '';
        };

        link = lib.mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Local file path or local directory path to install in system as a link:
            - sets 'source' to the given file or directory
            - sets 'kind' to 'link'
            - sets 'own' to 'default'
          '';
        };

        source = lib.mkOption {
          type = types.path;
          example = "../include/home/.dircolors";
          description = lib.mdDoc ''
            Path of the local file to store or a pre-stored path. Prefer setting this value using 
            the helper options 'copy', 'link', or 'text'.
            e.g. #1: ../include/home/.dircolors;
            e.g. #2: pkgs.writeText "root-.dircolors" (lib.fileContents ../include/home/.dircolors);
          '';
        };

        kind = lib.mkOption {
          type = types.enum [ "copy" "link" ];
          default = "link";
          description = lib.mdDoc ''
            Kind can be one of [ copy | link ] and indicates the type of object being 
            created. When 'copy' is used the user, group and filemode properties will be used to 
            specify the file's properties and likewise user, group and dirmode for directories. 
            Similarly for 'link' dirmode, user, and group will set the directory properties of 
            any directories needing to be created for the link.
          '';
        };

        op = lib.mkOption {
          type = types.enum [ "default" ];
          default = "default";
          description = lib.mdDoc ''
            Operation can be one of [ default ]. Place holder for future.
          '';
        };

        own = lib.mkOption {
          type = types.enum [ "default" "owned" "free" ];
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

        dirmode = lib.mkOption {
          type = types.str;
          default = "0755";
          example = "0700";
          description = lib.mdDoc "Mode of any directories being created";
        };

        filemode = lib.mkOption {
          type = types.str;
          default = "0644";
          example = "0777";
          description = lib.mdDoc "Mode of any files being created";
        };

        user = lib.mkOption {
          type = types.str;
          default = "${user}";
          description = lib.mdDoc "Owner of file being created and/or the directories.";
        };

        group = lib.mkOption {
          type = types.str;
          default = "${group}";
          description = lib.mdDoc "Group of file being created and/or the directories.";
        };
      };

      # config in this context will be the files.any."" definition
      config = {

        # Default the destination name to the attribute name
        target = lib.mkDefault "${prefix}${name}";

        # Set kind based off the convenience options [ copy | link ]
        kind = if (config.link != null) then (lib.mkForce "link")
          else lib.mkForce "copy";

        # Set default for future use
        op = lib.mkDefault "default";

        # Set default( i.e. files are owned and directories are not) but allows for user overrides
        own = lib.mkDefault "default";

        # Set based off the convenience options
        source = if (config.copy != null) then (lib.mkForce config.copy)
          else if (config.link != null) then (lib.mkForce config.link)
          else lib.mkIf (config.text != null) (lib.mkDerivedConfig options.text (pkgs.writeText name));
      };
    }
  ));
}
