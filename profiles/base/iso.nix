# iso configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
# --------------------------------------------------------------------------------------------------
{ args, pkgs, lib, ... }:
{
  imports = [
    # Import and activate home-manager
    args.home-manager.nixosModules.home-manager

    # I get a weird infinite recursion bug if I use ${pkgs} instead
    "${args.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../system/nix.nix
  ];

  home-manager = {
    extraSpecialArgs = { inherit args; };
    users.nixos = {
      home.file.".bash_profile".text = ''
        if [ ! if clu ]; then
          curl -sL -o clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
        fi
        chmod +x clu
        sudo ./clu -f https://github.com/phR0ze/nixos-config
      '';

      home = {
        username = "nixos";
        homeDirectory = "/home/nixos";
        stateVersion = args.systemSettings.stateVersion;
      };
    };
  };
  #programs.home-manager.enable = true;

  # Set the default user passwords
  users.users.nixos.password = "nixos";
  users.extraUsers.root.password = "nixos";

  #networking.hostName = "iso";

  environment.systemPackages = with pkgs; [
    git                 # Needed for clu installer automation
    jq                  # Needed for clu installer automation
  ];
}

# vim:set ts=2:sw=2:sts=2
