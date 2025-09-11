# Private Internet Access
#
# ### Description
# Private Internet Access is a paid VPN provider that is low cost and privacy focused. Using vopono 
# with PIA allows for routing specific applications over the VPN while keeping the rest of the system 
# running over the standard LAN.
#
# ### Deployment notes
# For this to work correctly you'll need some manual setup as well:
# 1. Run `vopono sync --protocol wireguard PrivateInternetAccess`
# 2. Enter your PIA credentials and answer the port forwarding No
# 3. Restart your service `systemctl --user restart APP-over-vpn`
#
# * Note: you can manually start with `xdg-open "/etc/xdg/autostart/${APP}-over-vpn.desktop"`
# * Service will not be restarted if it fails
# * Requires passwordless sudo access to be able to elevate privileges when needed
# * Validation can be done by using firefox as the app and navigating to 
#   https://www.privateinternetaccess.com/pages/whats-my-ip
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  nic = config.machine.net.nic.name;
  cfg = config.services.raw.private-internet-access;
in
{
  options = {
    services.raw.private-internet-access = {
      enable = lib.mkEnableOption "Configure a Private Internet Access based VPN service";
      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart VPN on login";
        type = types.bool;
        default = true;
      };
      app = lib.mkOption {
        description = lib.mdDoc "Applications to run over the VPN";
        type = types.str;
        default = "qbittorrent";
      };
      server = lib.mkOption {
        description = lib.mdDoc "VPN server to use";
        type = types.str;
        default = "us-saltlakecity";
      };
    };
  };
 
  config = lib.mkMerge [

    # Install the supporting software
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.wireguard-tools        # Wireguard VPN tooling
        pkgs.vopono                 # Network namespace automation
        pkgs.iptables               # Low level firewall tools
      ];    
    })

    # Configure to autostart after login
    # Creates `/etc/xdg/autostart/APP-over-vpn.desktop`
    (lib.mkIf (cfg.enable && cfg.autostart) {
      environment.etc."xdg/autostart/${cfg.app}-over-vpn.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=true
        Exec=${pkgs.writeScript "${cfg.app}-over-vpn" ''
          #!${pkgs.runtimeShell}
          if [[ -e "$HOME/.config/vopono" ]]; then
            vopono exec --interface ${nic} --provider PrivateInternetAccess --server ${cfg.server} --protocol wireguard ${cfg.app}
          fi
        ''}
      '';
    })
  ];
}
