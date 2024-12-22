# Declares files fileType for use in various files options
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }:
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
            indicated target path. To make this a link at the target location set 'kind="link"'.
            - sets 'source' to the given file
            - sets 'kind' to 'copy' by default
          '';
        };

        copy = lib.mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Local file path or local directory path to install in system. Copies during a 'clu' 
            install or update, but not for nixos-rebuild switch nor during reboots. Overwrites 
            existing files of the same name.
            - sets 'source' to the given file
            - sets 'kind' to 'copy' by default
            - sets 'own' to 'owned' by default
          '';
        };

        weakCopy = lib.mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Local file path or local directory path to install in system. Copies during a 'clu' 
            install or update, but not for nixos-rebuild switch nor during reboots. Only copies to 
            the destination if it doesn't exist or there is no record of an initial copy.
            - sets 'source' to the given file
            - sets 'kind' to 'copy' by default
            - sets 'own' to 'unowned' by default
          '';
        };

        link = lib.mkOption {
          default = null;
          type = types.nullOr types.path;
          description = lib.mdDoc ''
            Local file path or local directory path to install in system as a link. Overwrites 
            existing files of the same name.
            - sets 'source' to the given file or directory
            - sets 'kind' to 'link' by default
          '';
        };

        source = lib.mkOption {
          type = types.path;
          example = "../include/home/.dircolors";
          description = lib.mdDoc ''
            Path of the local file to store or a pre-stored path. Prefer setting this value using 
            the helper options 'copy', 'link', or 'text'.
            e.g. #1: ../include/home/.dircolors;
            e.g. #2: pkgs.writeText ".dircolors" (lib.fileContents ../include/home/.dircolors);
          '';
        };

        kind = lib.mkOption {
          type = types.enum [ "default" "copy" "link" ];
          default = "default";
          description = lib.mdDoc ''
            Kind can be one of [ default | copy | link ] and indicates the type of object being 
            created. When 'copy' is used the user, group and filemode properties will be used to 
            specify the file's properties and likewise user, group and dirmode for directories. 
            Similarly for 'link' dirmode, user, and group will set the directory properties of 
            any directories needing to be created for the link. A value of 'default' indicates the 
            user doesn't have a strong opionion and the system can choose how this is used based on 
            the higher level functions.
          '';
        };

        _kind = lib.mkOption {
          type = types.enum [ "copy" "link" ];
          description = lib.mdDoc ''
            This is an internally computed value of what 'own' should be based on the system's 
            defaults and the user's choices and should not be set directly by the user.
          '';
        };

        own = lib.mkOption {
          type = types.enum [ "default" "owned" "unowned" ];
          default = "default";
          description = lib.mdDoc ''
            Whether to own the file or directory or not. When a file or directory is owned it is 
            automatically deleted if your configuration no longer uses it. It is also overwritten 
            on every update. To avoid overwriting the original source on updates use the `weakCopy` 
            instead which sets own to unowned and only copies the initial time or if it doesn't 
            exist. Own is true by default for links.
          '';
        };

        _own = lib.mkOption {
          type = types.enum [ "owned" "unowned" ];
          description = lib.mdDoc ''
            This is an internally computed value of what 'own' should be based on the system's 
            defaults and the user's choices and should not be set directly by the user.
          '';
        };

        op = lib.mkOption {
          type = types.str;
          default = "default";
          description = lib.mdDoc ''
            Placeholder for a future operation
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

        # Set kind based off the convenience options [ default | copy | link ]
        _kind = if (config.kind != "default") then (lib.mkForce config.kind)
          else if (config.copy != null || config.weakCopy != null || config.text != null) then (lib.mkForce "copy")
          else lib.mkForce "link";

        # Set default for future use
        op = lib.mkDefault "default";

        # Set default (i.e. files are owned and directories are not) but allows for user overrides
        _own = if (config.own != "default") then (lib.mkForce config.own)
          else if (config.weakCopy != null) then (lib.mkForce "unowned")
          else (lib.mkForce "owned");

        # Set based off the convenience options
        source = if (config.copy != null) then (lib.mkForce config.copy)
          else if (config.weakCopy != null) then (lib.mkForce config.weakCopy)
          else if (config.link != null) then (lib.mkForce config.link)
          else lib.mkIf (config.text != null) (lib.mkDerivedConfig options.text (pkgs.writeText name));
      };
    }
  ));
}
