# Git configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  programs.git = {
    enable = true;
    config = {
      user = {
        name = args.settings.git_user;
        email = args.settings.git_email;
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
