# Private Internet Access
#
# ### Description
# Private Internet Access is a paid VPN provider that is low cost and privacy focused. Using vopono 
# with PIA allows for routing specific applications over the VPN while keeping the rest of the system 
# running over the standard LAN.
#
# ### Deployment notes
# - For this to work correctly you'll some manual setup as well
# - 1. Run `vopono sync --protocol wireguard PrivateInternetAccess`
# - 2. Enter your PIA credentials and answer the port forwarding no
# - 3. Restart your service `systemctl --user restart APP-over-vpn`
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.raw.private-internet-access;
  machine = config.machine;
in
{
  options = {
    services.raw.private-internet-access = {
      enable = lib.mkEnableOption "Configure a Private Internet Access based VPN service";
      app = lib.mkOption {
        description = lib.mdDoc "Applications to run over the VPN";
        type = types.str;
        default = "firefox";
      };
      server = lib.mkOption {
        description = lib.mdDoc "VPN server to use";
        type = types.str;
        default = "us-saltlakecity";
      };
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # Install the supporting software
      environment.systemPackages = [
        pkgs.wireguard-tools        # Wireguard VPN tooling
        pkgs.vopono                 # Network namespace automation
      ];    

      # Configure services to run over the VPN
      systemd.user.services."${cfg.app}-over-vpn" = {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "simple";
          Restart = "on-success";

  uid = config.users.users.${user_name}.uid;
  gid = config.users.groups."users".gid;
          User = "${machine.user.name}";
          Group = "${machine.user.group}";
          ExecStart = ''vopono exec --provider PrivateInternetAccess --server ${cfg.server} --protocol wireguard ${cfg.app}'';
        };
      };
    })
  ];
}
