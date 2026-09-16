# Git
# Distributed version control system.
#
# ### Details
# - Configures user identity from the given user/email options
# - Sets vim as the default editor
# - Enables rebase on pull
# - Adds 'git d' alias for 'git diff --word-diff=color'
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.env.git;
in
{
  options = {
    system.env.git = {
      enable = lib.mkEnableOption "Configure git with sensible defaults";

      user = lib.mkOption {
        description = lib.mdDoc "Git user name";
        type = lib.types.str;
      };

      email = lib.mkOption {
        description = lib.mdDoc "Git email address";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      {
        assertion = cfg.user != "" && cfg.email != "";
        message = ''
          system.env.git is enabled but `system.env.git.user`/`system.env.git.email` are not
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
