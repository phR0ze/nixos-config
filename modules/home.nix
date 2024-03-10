# Home option
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;

  # ### Home Manager
  # Home Manager's solution is to use a JSON payload and live xfconf-query calls after the system is
  # up and running to inject configuration. However this depends on the home manager daemon with 
  # possible runtime failures due to dbus or xfconf-query errors which I'd rather not incur.
  #
  # ### Solution
  # The nix way would be to make it declarative and readonly similar to environment.etc which lays 
  # down configuration with a readonly link to the nix store.
  # 1. Create a new home.file.".vimrc".source = ./vimrc;
  # 2. Use the existing security.pam.services.login.makeHomeDir for defaults

  # We can leverage the write builders to create files in the user's home directory
  # https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText

  #home.config.""
  #home.""

  # pkgs.writeShellScript

# Writing NixOS Modules
# https://nixos.org/manual/nixos/unstable/#sec-writing-modules
let

  #cfg = config.apps.galculator;
  #homedir = config.users.users.${args.settings.username}.home;

  etc' = filter (f: f.enable) (attrValues config.environment.etc);

  etc = pkgs.runCommandLocal "etc" {
    # This is needed for the systemd module
    passthru.targets = map (x: x.target) etc';
  } /* sh */ ''
    set -euo pipefail

    makeEtcEntry() {
      src="$1"
      target="$2"
      mode="$3"
      user="$4"
      group="$5"

      if [[ "$src" = *'*'* ]]; then
        # If the source name contains '*', perform globbing.
        mkdir -p "$out/etc/$target"
        for fn in $src; do
            ln -s "$fn" "$out/etc/$target/"
        done
      else

        mkdir -p "$out/etc/$(dirname "$target")"
        if ! [ -e "$out/etc/$target" ]; then
          ln -s "$src" "$out/etc/$target"
        else
          echo "duplicate entry $target -> $src"
          if [ "$(readlink "$out/etc/$target")" != "$src" ]; then
            echo "mismatched duplicate entry $(readlink "$out/etc/$target") <-> $src"
            ret=1

            continue
          fi
        fi

        if [ "$mode" != symlink ]; then
          echo "$mode" > "$out/etc/$target.mode"
          echo "$user" > "$out/etc/$target.uid"
          echo "$group" > "$out/etc/$target.gid"
        fi
      fi
    }

    mkdir -p "$out/etc"
    ${concatMapStringsSep "\n" (etcEntry: escapeShellArgs [
      "makeEtcEntry"
      # Force local source paths to be added to the store
      "${etcEntry.source}"
      etcEntry.target
      etcEntry.mode
      etcEntry.user
      etcEntry.group
    ]) etc'}
  '';
in
{
  # Option interface
  # ------------------------------------------------------------------------------------------------
  # Inspired from nixpkg's etc.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/etc/etc.nix
  # ------------------------------------------------------------------------------------------------
  options = {
    environment.home = mkOption {
      default = {};
      example = literalExpression ''
        {
          example-configuration-file = {
            source = "/nix/store/.../etc/dir/file.conf.example";
            mode = "0440";
          };
          "default/useradd".text = "GROUP=100 ...";
        }
      '';
      description = lib.mdDoc ''
        Set of files to be linked in {file}`/etc`.
      '';

      type = with types; attrsOf (submodule (
        { name, config, options, ... }: {
          options = {

            enable = mkOption {
              type = types.bool;
              default = true;
              description = lib.mdDoc ''
                Whether this /home/$USER file should be generated. This
                option allows specific /home/$USER files to be disabled.
              '';
            };

            target = mkOption {
              type = types.str;
              description = lib.mdDoc ''
                Name of symlink (relative to {file}`/etc`).
                Defaults to the attribute name.
              '';
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

            mode = mkOption {
              type = types.str;
              default = "symlink";
              example = "0600";
              description = lib.mdDoc ''
                If set to something else than `symlink`, the file is
                copied instead of symlinked, with the given file mode.
              '';
            };

            uid = mkOption {
              default = 0;
              type = types.int;
              description = lib.mdDoc ''
                UID of created file. Only takes effect when the file is
                copied (that is, the mode is not 'symlink').
                '';
            };

            gid = mkOption {
              default = 0;
              type = types.int;
              description = lib.mdDoc ''
                GID of created file. Only takes effect when the file is
                copied (that is, the mode is not 'symlink').
              '';
            };

            user = mkOption {
              default = "+${toString config.uid}";
              type = types.str;
              description = lib.mdDoc ''
                User name of created file. Only takes effect when the file
                is copied (that is, the mode is not 'symlink').
                Changing this option takes precedence over `uid`.
              '';
            };

            group = mkOption {
              default = "+${toString config.gid}";
              type = types.str;
              description = lib.mdDoc ''
                Group name of created file.
                Only takes effect when the file is copied (that is, the mode is not 'symlink').
                Changing this option takes precedence over `gid`.
              '';
            };

          };

          config = {
            target = mkDefault name;
            source = mkIf (config.text != null) (
              let name' = "etc-" + lib.replaceStrings ["/"] ["-"] name;
              in mkDerivedConfig options.text (pkgs.writeText name')
            );
          };
        }));
    };
  };

  # Option implementation
  # ------------------------------------------------------------------------------------------------
  config = {
    system.build.etc = etc;
    system.build.etcActivationCommands =
      ''
        # Set up the statically computed bits of /etc.
        echo "setting up /etc..."
        ${pkgs.perl.withPackages (p: [ p.FileSlurp ])}/bin/perl ${./setup-etc.pl} ${etc}/etc
      '';
  };
}
