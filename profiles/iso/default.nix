# ISO default configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
#
# ### Features
# - Size: 986.0 MiB
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, args, ... }: with lib;
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ./packages.nix
    ../../options
    ../../modules/nix.nix
    ../../modules/users.nix
  ];

  # ISO image configuration
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/installation-cd-base.nix
  # Original example naming: "nixos-23.11.20240225.5bf1cad-x86_64-linux.iso"
  isoImage.isoBaseName = "nixos-installer";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # Adding packages needed for the clu installer automation
  environment.systemPackages = with pkgs; [
    git
    jq
  ];

  # Configure /etc/bashrc to launch our installer automation 'clu'
  programs.bash.promptPluginInit = ''
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
}
