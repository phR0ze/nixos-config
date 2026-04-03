# Git
# Distributed version control system.
#
# ### Details
# - Configures user identity from machine args
# - Sets vim as the default editor
# - Enables rebase on pull
# - Defaults `git diff` to word-diff=color mode
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.apps.dev.git;
  machine = config.machine;
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
          name = machine.git.user;
          email = machine.git.email;
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
          diff = "diff --word-diff=color";
        };
      };
    };
  };
}
