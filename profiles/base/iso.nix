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

  # Configure home-manager for ISO to have a script that is automatically run on login
  # to launcher our installer automation 'clu'
  home-manager = {
    extraSpecialArgs = { inherit args; };
    users.nixos = {
      home.file.".bash_profile".text = ''
        none="\e[m"
        red="\e[1;31m"
        cyan="\e[1;36m"
        green="\e[1;32m"
        yellow="\e[1;33m"

        # Wait for the network to be live
        echo "${cyan}:: Checking if network is ready${none}"
        while ! ping -c 4 google.com &>/dev/null; do
          echo "   Waiting on the network"
          sleep 1
        done
        echo "   Network is ready"

        # Download the installer as needed
        echo "${cyan}:: Checking for the installer script${none}"
        if [ ! -f /home/nixos/clu ]; then
          echo "   Downloading the installer script"
          curl -sL -o /home/nixos/clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
        fi
        [ -f /home/nixos/clu ] && echo "   Installer script exists"

        # Execute the installer script
        echo "${cyan}:: Executing the installer script${none}"
        chmod +x /home/nixos/clu
        sudo /home/nixos/clu -f https://github.com/phR0ze/nixos-config
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
