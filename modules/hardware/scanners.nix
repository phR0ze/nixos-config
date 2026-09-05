# Scanner configuration
#
# ### Details
# - https://nixos.wiki/wiki/Scanners
#---------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
let
  host = config.host;
in
{
  hardware.sane = {
    enable = true; 
    extraBackends = [
      pkgs.epkowa                         # Epson scanner support
      pkgs.hplipWithPlugin                # HP scanner support
      pkgs.utsushi                        # Generic scanner support
    ];
  };

  services.udev.packages = [
    pkgs.utsushi
  ];

  users.users.${host.user.name}.extraGroups = [ "scanner" "lp" ];
}
