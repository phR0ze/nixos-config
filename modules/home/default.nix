# Default home manager configuration
#---------------------------------------------------------------------------------------------------
# This or other configuration files in this directory are used as home-manager's entry points to
# control any home-manager modules e.g. ../terminal/dircolors.nix. I'm clearly documenting in the
# header of any home-manager modules i.e. nix files that are required to be called from home-manager
# to handle home-manager specific options.
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
    users.${args.settings.username} = { args, ... }:
    {
      imports = [
        ../terminal/dircolors.nix
      ];
    
      home = {
        username = "${args.settings.username}";
        homeDirectory = "/home/${args.settings.username}";
        stateVersion = args.settings.stateVersion;
      };
    };
  };
}

# vim:set ts=2:sw=2:sts=2
