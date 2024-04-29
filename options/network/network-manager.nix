# Network manager configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.network.network-manager;
  nmcfg = config.networking.networkmanager;

  dhcpName = "dhcp.nmconnection";
  staticName = "static.nmconnection";

  # Higher values of autoconnect-priority will be given priority
  connections = pkgs.runCommandLocal staticName {} ''
      mkdir $out

      target="$out/${dhcpName}"
      echo "[connection]" >> $target
      echo "id=Wired dhcp" >> $target
      echo "uuid=$(${pkgs.util-linux}/bin/uuidgen)" >> $target
      echo "type=ethernet" >> $target
      echo "autoconnect-priority=0" >> $target
      echo "" >> $target
      echo "[ipv4]" >> $target
      echo "method=auto" >> $target
      echo "" >> $target
      echo "[ipv6]" >> $target
      echo "method=disabled" >> $target

      target="$out/${staticName}"
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
   '';
in
{
  options = {
    network.network-manager = {
      enable = lib.mkEnableOption "Install and configure network manager";
    };
  };
  
  config = lib.mkMerge [
    (lib.mkIf (args.settings.static_ip != "") {
      environment.etc."networkmanager/system-connections/${staticname}" = {
        mode = "0600";
        source = "${connections}/${staticname}";
      };
    })
    (lib.mkIf (cfg.enable) {

      # Its ok to always have dhcp as static has higher priority when exists
      environment.etc."NetworkManager/system-connections/${dhcpName}" = {
        mode = "0600";
        source = "${connections}/${dhcpName}";
      };

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
