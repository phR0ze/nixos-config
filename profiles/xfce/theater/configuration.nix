# XFCE theater configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../work/configuration.nix # Personal is essentially work system + games
    ../../system/app/gamemode.nix
    ../../system/app/steam.nix
    ../../system/app/prismlauncher.nix
    ../../system/security/doas.nix
    ../../system/security/gpg.nix
    ../../system/security/blocklist.nix
    ../../system/security/firewall.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
