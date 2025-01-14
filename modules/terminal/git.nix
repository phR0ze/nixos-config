# Git configuration
#---------------------------------------------------------------------------------------------------
{ config, ... }:
let
  machine = config.machine;
in
{
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
    };
  };
}
