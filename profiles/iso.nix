# ISO default configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
#
# ### Features
# - Automatically run installation wizard to guide you through the install
# - Automation for installing NixOS including partitioning and customization
# - Packages included on ISO for optimimal install speed and offline installations
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, modulesPath, ... }:
let
  machine = config.machine;
in
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    (./. + machine.profile + ".nix")
  ];

  # ISO image configuration
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/installation-cd-base.nix
  # Original example naming: "nixos-23.11.20240225.5bf1cad-x86_64-linux.iso"
  isoImage.isoBaseName = "cyberlinux";
  isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.volumeID = "${config.isoImage.isoBaseName}-installer";

  # Clearing out the hashed form to avoid the warning during ISO creation.
  # The passwords are set in the ../../modules/users.nix file via the flake_private.nix
  users.users.root.initialHashedPassword = lib.mkForce null;
  users.users.nixos.initialHashedPassword = lib.mkForce null;
  services.openssh.settings.PermitRootLogin = "yes";

  # Some more help text.
  services.getty.helpLine = lib.mkForce ''
    The "nixos" and "root" account passwords are set to ${machine.user.pass}.

    If you need a wireless connection, type
    `sudo systemctl start wpa_supplicant` and configure a
    network using `wpa_cli`. See the NixOS manual for details.
  '';

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
