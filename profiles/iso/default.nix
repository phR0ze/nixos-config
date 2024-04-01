# ISO default configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
#
# ### Features
# - Automatically run installation wizard to guide you through the install
# - Automation for installing NixOS including partitioning and customization
# - Packages included on ISO for optimimal install speed and offline installations
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ../xfce/develop.nix
  ];

  # ISO image configuration
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/installation-cd-base.nix
  # Original example naming: "nixos-23.11.20240225.5bf1cad-x86_64-linux.iso"
  isoImage.isoBaseName = "nixos-installer";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";

  # Set ISO nixos user's password to default in flake_opts.nix and clear out the
  # hashed form to avoid the warning during ISO creation.
  users.users.root.initialHashedPassword = lib.mkForce null;
  users.users.nixos.initialHashedPassword = lib.mkForce null;
  users.users.nixos.initialPassword = lib.mkForce args.settings.userpass;

  # Adding packages for the ISO environment
  environment.systemPackages = with pkgs; [
    git         # dependency for clu installer automation
    jq          # dependency for clu installer automation
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
