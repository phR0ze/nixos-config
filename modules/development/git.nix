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

# vim:set ts=2:sw=2:sts=2
