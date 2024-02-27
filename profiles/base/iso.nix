# iso configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
#
# ### Features
# - Size: 986.0 MiB
# --------------------------------------------------------------------------------------------------
{ args, pkgs, lib, ... }:
{
  imports = [
    # Import and activate home-manager
    args.home-manager.nixosModules.home-manager

    # I get a weird infinite recursion bug if I use ${pkgs} instead
    "${args.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../../modules/nix.nix
  ];

  # Configure home-manager for ISO to have a script that is automatically run on login
  # to launcher our installer automation 'clu'
  home-manager = {
    extraSpecialArgs = { inherit args; };
    users.nixos = {
      home.file.".bash_profile".text = ''
        # Wait for the network to be live
        echo ":: Checking if network is ready"
        while ! ping -c 4 google.com &>/dev/null; do
          echo "   Waiting on the network"
          sleep 1
        done
        echo "   Network is ready"

        # Clone the installer repo as needed
        echo ":: Checking for the nixos-config repo"
        if [ ! -d /home/nixos/nixos-config ]; then
          echo "   Downloading https://github.com/phR0ze/nixos-config"
          git clone https://github.com/phR0ze/nixos-config /home/nixos/nixos-config
        fi
        [ -f /home/nixos/nixos-config/clu ] && echo "   Installer script exists"

        # Execute the installer script
        echo ":: Executing the installer script"
        chmod +x /home/nixos/nixos-config/clu
        sudo /home/nixos/nixos-config/clu install
      '';

      home = {
        username = "nixos";
        homeDirectory = "/home/nixos";
        stateVersion = args.settings.stateVersion;
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
