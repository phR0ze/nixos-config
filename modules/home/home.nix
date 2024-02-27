{ args, ... }:
{
  imports = [
    ../terminal/dircolors.nix
  ];

  home = {
    username = "${args.settings.username}";
    homeDirectory = "/home/${args.settings.username}";
    stateVersion = args.settings.stateVersion;
  };
}

# vim:set ts=2:sw=2:sts=2
