# Git configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  programs.git = {
    enable = true;
    config = {
      user = {
        name = args.git_user;
        email = args.git_email;
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
