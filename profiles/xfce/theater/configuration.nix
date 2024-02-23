# XFCE theater configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../app/gamemode.nix
    ../../app/steam.nix
    ../../app/prismlauncher.nix
    ../../security/doas.nix
    ../../security/gpg.nix
    ../../security/blocklist.nix
    ../../security/firewall.nix
  ];

  # Install system packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    kodi
    firefox
    vim
    wget
  ];
}

# vim:set ts=2:sw=2:sts=2
