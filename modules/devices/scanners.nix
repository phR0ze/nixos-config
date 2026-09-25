# Scanner configuration
#
# ### Details
# - https://nixos.wiki/wiki/Scanners
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.devices.scanners;
  host = config.host;
in
{
  options = {
    devices.scanners = {
      enable = lib.mkEnableOption "Install and configure scanner support";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
