# Mullvad VPN service
#
# ### Description
# Mullvad offers anonymous registration. They don't require your personal information to create an 
# Mullvad is a privacy focused VPN provider. They offer anonymous registration via a generated
# account number. With the anonymous account you can then use a voucher to pay for VPN time
# anonymously as well.
#
# ### Deployment notes
# For this to work correctly you'll need some manual setup as well:
# 1. Ensure the daemon is running `sudo systemctl status mullvad-daemon`
# 2. Login to your account with your auto generated account number
# 3. Configure using [Mullvad config guide](https://github.com/phR0ze/tech-docs/tree/main/src/networking/vpns/mullvad)
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.raw.mullvad;
in
{
  options = {
    services.raw.mullvad = {
      enable = lib.mkEnableOption "Configure Mullvad VPN service";
    };
  };
 
  config = lib.mkMerge [

    # Install the supporting software
    (lib.mkIf cfg.enable {
      services.mullvad-vpn.enable = true;

      environment.systemPackages = [
        pkgs.mullvad-vpn            # Mullvad GUI
        pkgs.wireguard-tools        # Wireguard VPN tooling
        pkgs.iptables               # Low level firewall tools
      ];    
    })
  ];
}
