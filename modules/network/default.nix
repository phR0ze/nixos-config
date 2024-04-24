# Default networking configuration
#
# ### Features
# - Disables IPv6
# - DHCP systemd-networkd networking
# - Configures CloudFlare DNS
# - Support optional static ip addresses
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  staticConn = lib.mkIf (args.settings.static_ip != "") (
    pkgs.runCommandLocal "static.nmconnection" {} ''
      mkdir $out
      target="$out/static.nmconnection"

      echo "[connection]" >> $target
      echo "id=Wired static" >> $target
      echo "uuid=$(${pkgs.util-linux}/bin/uuidgen)" >> $target
      echo "type=ethernet" >> $target
      echo "autoconnect-priority=1" >> $target
      echo "" >> $target
      echo "[ipv4]" >> $target
      echo "method=manual" >> $target
      echo "address=${args.settings.static_ip}" >> $target
      echo "gateway=${args.settings.gateway}" >> $target
      echo "" >> $target
      echo "[ipv6]" >> $target
      echo "method=disabled" >> $target
    '');
in
{
  config = lib.mkMerge [
    (lib.mkIf (args.settings.static_ip != "") {
      networking.useDHCP = false;     # disable dhcp for all interfaces
      environment.etc."NetworkManager/system-connections/static.nmconnection" = {
        mode = "0600";
        source = staticConn;
      };
    })

    ({
      networking.hostName = args.settings.hostname;
      networking.enableIPv6 = false;

      # XFCE enables networkmanager and nm-applet by default
      networking.networkmanager = {
        enable = true;
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization technologies
          "interface-name:docker*"
          "interface-name:vboxnet*"
          "interface-name:vmnet*"
        ];
      };

      # Use systemd-resolved for DNS
      # Uses networking.nameservers as the primary DNS servers see /etc/systemd/resolved.conf
      networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
      services.resolved = {
        enable = true;
        dnssec = "true";
        #domains = [ "example.com" ]
        fallbackDns = [ "8.8.8.8" "8.8.4.4" ]; # fallback on google dns
      };

      # Enables ability for user to make network manager changes
      users.users.${args.settings.username} = {
        extraGroups = [ "networkmanager" ];
      };

     # services.avahi = lib.mkIf (config.my.mdns && !config.boot.isContainer) {
     #   enable = true;
     #   nssmdns = true;
     # };
    })
  ];
}
