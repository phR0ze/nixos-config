# Scanner configuration
#
# ### Details
# - https://nixos.wiki/wiki/Scanners
#---------------------------------------------------------------------------------------------------
{ config, pkgs, ... }:
let
  machine = config.machine;
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

  users.users.${machine.user.name}.extraGroups = [ "scanner" "lp" ];
}
