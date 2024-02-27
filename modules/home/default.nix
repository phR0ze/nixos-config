# Default home manager configuration
#---------------------------------------------------------------------------------------------------
# This or other 'home' configuration files in this directory are used as home-manager's entry points
# to control any home-manager dependent configurations e.g. ../terminal/dircolors.nix. For nix files
# that depend on home-manager I'll document them as requiring home-manager.
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  imports = [
    args.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = false;
    extraSpecialArgs = { inherit args; }; # passes 'args' to home-manager modules

    # Define root user

    # Define system user
    users.${args.settings.username} = import ./home.nix;
    #users.${args.settings.username} = {
    #  home = {
    #    username = "${args.settings.username}";
    #    homeDirectory = "/home/${args.settings.username}";
    #    stateVersion = args.settings.stateVersion;
    #  };
    #};
  };
}

# vim:set ts=2:sw=2:sts=2
