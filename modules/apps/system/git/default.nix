# Git
# Distributed version control system.
#
# ### Details
# - Configures user identity from the given user/email options
# - Sets vim as the default editor
# - Enables rebase on pull
# - Adds 'git d' alias for 'git diff --word-diff=color'
# - Applies a global excludesFile so machine-local dirs (e.g. .claude/) never need a
#   manual ~/.config/git/ignore on each new host
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.git;
in
{
  options = {
    apps.system.git = {
      enable = lib.mkEnableOption "Configure git with sensible defaults";

      user = lib.mkOption {
        description = lib.mdDoc "Git user name";
        type = lib.types.str;
      };

      email = lib.mkOption {
        description = lib.mdDoc "Git email address";
        type = lib.types.str;
      };

      ignores = lib.mkOption {
        description = lib.mdDoc "Global gitignore patterns applied to every repo";
        type = lib.types.listOf lib.types.str;
        default = [ "**/.claude/" ];
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      {
        assertion = cfg.user != "" && cfg.email != "";
        message = ''
          apps.system.git is enabled but `apps.system.git.user`/`apps.system.git.email` are not
          set. Provide both, e.g. via `config.host.git.user`/`config.host.git.email`.
        '';
      }
    ];

    programs.git = {
      enable = true;
      config = {
        user = {
          name = cfg.user;
          email = cfg.email;
        };
        core = {
          editor = "vim";
          excludesFile = toString (pkgs.writeText "gitignore-global" (
            lib.concatStringsSep "\n" cfg.ignores
          ));
        };
        pull = {
          rebase = true;
        };
        push = {
          default = "simple";
        };
        init = {
          defaultBranch = "main";
        };
        safe = {
          directory = "/etc/nixos";
        };
        alias = {
          d = "diff --word-diff=color";
        };
      };
    };
  };
}
