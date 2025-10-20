# ISO default configuration
# --------------------------------------------------------------------------------------------------
# https://nixos.wiki/wiki/Creating_a_NixOS_live_CD
#
# ### Build instructions
# ./clu build iso
#
# ### Features
# - Automatically run installation wizard to guide you through the install
# - Automation for installing NixOS including partitioning and customization
# - Includes packages on ISO for offline installations
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, modulesPath, ... }:
let
  machine = config.machine;
in
{
  machine.type.iso = true;
  machine.autologin = true;
  machine.hostname = "nixos";
  machine.user.name = "nixos";
  machine.user.group = "nixos";

  imports = [
    # The ISO building automation I'm levaraging from Nix will automatically include all derevations 
    # in the iso that were used during the build. Thus the 'machine.target' called out below will 
    # pull in any derivations needed to build that profile.
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    (../${args.target})
  ];

  # ISO image configuration
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/iso-image.nix
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/cd-dvd/installation-cd-base.nix
  # Original example naming: "nixos-23.11.20240225.5bf1cad-x86_64-linux"
  image.baseName = lib.mkForce "cyberlinux-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
  isoImage.volumeID = "cyberlinux-installer";

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

  # Add a marker to pass ISO state to install
  environment.etc."iso-build-profile".text = args.target;

  # Configure /etc/bashrc to launch our installer automation 'clu'
  programs.bash.promptPluginInit = ''
    echo ":: Executing the installer script"
    sudo ${pkgs.clu}/bin/clu install
  '';
}
