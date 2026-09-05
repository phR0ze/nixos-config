# Git
# Distributed version control system.
#
# ### Details
# - Configures user identity from host args
# - Sets vim as the default editor
# - Enables rebase on pull
# - Adds 'git d' alias for 'git diff --word-diff=color'
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.apps.dev.git;
  host = config.host;
in
{
  options = {
    apps.dev.git = {
      enable = lib.mkEnableOption "Configure git with sensible defaults";
    };
  };

  config = lib.mkIf (cfg.enable) {
    programs.git = {
      enable = true;
      config = {
        user = {
          name = host.git.user;
          email = host.git.email;
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
