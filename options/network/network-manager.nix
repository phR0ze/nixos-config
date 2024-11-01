# Network manager configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.network.network-manager;

  dhcpName = "dhcp.nmconnection";
  staticName = "static.nmconnection";

  # Higher values of autoconnect-priority will be given priority
  connections = pkgs.runCommandLocal "connections" {} ''
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
      environment.etc."NetworkManager/system-connections/${staticName}" = {
        mode = "0600";
        source = "${connections}/${staticName}";
      };
    })
    (lib.mkIf (cfg.enable) {
      networking.enableIPv6 = false;
      networking.hostName = args.settings.hostname;

      # Enable networkmanager and nm-applet by default
      networking.networkmanager = {
        enable = true;
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization technologies
          "interface-name:docker*"
          "interface-name:vboxnet*"
          "interface-name:vmnet*"
        ];
      };

      # Enables ability for user to make network manager changes
      users.users.${args.settings.username}.extraGroups = [ "networkmanager" ];

      # Its ok to always have dhcp as static has higher priority when exists
      environment.etc."NetworkManager/system-connections/${dhcpName}" = {
        mode = "0600";
        source = "${connections}/${dhcpName}";
      };

      # Use systemd-resolved for DNS
      # Uses networking.nameservers as the primary DNS servers see /etc/systemd/resolved.conf
      networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
      services.resolved = {
        enable = true;

        # using `true` will require and thus break if DNS servers don't support it like VPNs
        dnssec = "allow-downgrade";

        #domains = [ "example.com" ]
        fallbackDns = [ "8.8.8.8" "8.8.4.4" ]; # fallback on google dns
      };
    })
  ];
}
