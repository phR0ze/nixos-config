# Warcraft2
#
# Firewall exceptions needed:
# * GOG IPXWrapper: UDP 54792
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.games.warcraft2;
in
{
  options = {
    apps.games.warcraft2 = {
      enable = lib.mkEnableOption "Configure system for warcraft2";
      allowIPXMultiPlayer= lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable firewall rules for IPX multi-player.";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Allow multi-player IPX connections through the firewall
    # View rules with: sudo iptables -S
    networking.firewall.enable = false;
#    networking.firewall.interfaces."${config.networking.vnic0}" = lib.mkIf (cfg.allowIPXMultiPlayer) {
#      enable = false;
#      allowedUDPPorts = [ 54792 ];
#    };
  };
}
