# Default home manager configuration
#---------------------------------------------------------------------------------------------------
# This or other configuration files in this directory are used as home-manager's entry points to
# control any home-manager modules e.g. dircolors.nix
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    args.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    # By default Home Manager uses its own private pkgs instance. By setting this value to true
    # Home Manager will instead use the global pkgs configured by your system flake.
    useGlobalPkgs = true;

    # Don't use the users.users.<name>.packages option
    useUserPackages = false;

    # This passes 'args' to home-manager modules in a similar way that specialArgs at the top
    # level passes args into this nix module.
    extraSpecialArgs = { inherit args; };

    # Defines modules to be used for all users except for root
    # sharedModules = [ ];

    # Define system user
    users.${args.settings.username} = { pkgs, args, ... }:
    {
#      imports = [
#        ./dircolors
#      ];
    
      home = {
        username = "${args.settings.username}";
        homeDirectory = "/home/${args.settings.username}";
        stateVersion = args.settings.stateVersion;
      };
    };
  };
}

# vim:set ts=2:sw=2:sts=2
