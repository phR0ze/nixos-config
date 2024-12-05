# Adguard Home configuration
# - https://github.com/AdguardTeam/AdGuardHome
# - https://adguard.com/en/adguard-home/overview.html
#
# ### Description
# Privacy protection center for you and your devices. Free and open source, powerful network-wide ads
# and trackers blocking DNS server. Adguard Home operates as a DNS server that re-routes tarcking
# domains to a "black-hole", thus preventing your devices from connecting to those servers
#
# - Blocking ads and trackers
# - Customizing blocklists
# - Built-in DHCP server
# - HTTPS for the Admin interface
# - Encrypted DNS upstream servers
# - Blocking phishing and malware domains
# - Parental control (blocking adult domains)
# - Force Safe search on search engines
#
# ### Deployment Features
# - App is exposed to the LAN as a first class citizen to allow it to log correct IP addresses
# - App data is persisted at /var/lib/$APP
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  app = config.homelab.adguard;
in
{
  options = {
    homelab.adguard = {
      enable = lib.mkEnableOption "Deploy container based Adguard Home";

      name = lib.mkOption {
        description = lib.mdDoc "App name to use for supporting components";
        type = types.str;
        default = "adguard";
      };

      nic = lib.mkOption {
        description = lib.mdDoc "Parent NIC for the app macvlan";
        type = types.str;
        default = "${args.settings.nic0}";
      };

      subnet = lib.mkOption {
        description = lib.mdDoc "Network subnet to use for container macvlan";
        type = types.str;
        default = "${args.settings.subnet}";
      };

      gateway = lib.mkOption {
        description = lib.mdDoc "Network gateway to use for container macvlan";
        type = types.str;
        default = "${args.settings.gateway}";
      };

      hostIP = lib.mkOption {
        description = lib.mdDoc "IP address to use for the host app macvlan";
        type = types.str;
        default = "192.168.1.52";
      };

      containerIP = lib.mkOption {
        description = lib.mdDoc "IP address to use for the container app macvlan";
        type = types.str;
        default = "192.168.1.53";
      };

      port = lib.mkOption {
        description = lib.mdDoc "Port to use for Web Interface on the macvlan";
        type = types.port;
        default = 80;
        example = {
          port = 80;
        };
      };
    };
  };
 
  config = lib.mkIf app.enable {
    assertions = [
      { assertion = ("${app.nic}" != "");
        message = "Application parent NIC not specified, please set 'nic'"; }
      { assertion = ("${app.subnet}" != "");
        message = "Network subnet not specified, please set 'subnet'"; }
      { assertion = ("${app.gateway}" != "");
        message = "Network gateway not specified, please set 'gateway'"; }
      { assertion = ("${app.hostIP}" != "");
        message = "Host macvlan IP not specified, please set 'hostIP'"; }
      { assertion = ("${app.containerIP}" != "");
        message = "Container macvlan IP not specified, please set 'containerIP'"; }
    ];

    # Requires podman virtualization to be configured
    virtualization.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/conf 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/work 0750 ${args.settings.username} - -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # https://github.com/AdguardTeam/AdGuardHome/wiki/Docker
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/adguard/adguardhome:latest";
      autoStart = true;
      hostname = "${app.name}";
#      ports = [
#        "${app.ip}:53:53/tcp" "${app.ip}:53:53/udp"         # plain DNS
#        "${app.ip}:${toString app.port}:80/tcp"             # web interface
#        "${app.ip}:3000:3000/tcp"                           # setup web interface
#        #"${app.ip}:67:67/udp" "${app.ip}:68:68/udp"         # add if using as DHCP server
#        #"${app.ip}:443:443/tcp" "${app.ip}:443:443/udp"     # add if using as HTTPS/DNS over HTTPS server
#        #"${app.ip}:853:853/tcp"                             # add if using as DNS over TLS server
#        #"${app.ip}:853:853/udp"                             # add if using as DNS over QUIC server
#        #"${app.ip}:5443:5443/tcp" "${app.ip}:5443:5443/udp" # add if using AdGuard as DNSCrypt server
#        #"${app.ip}:6060:6060/tcp"                           # debugging profiles
#      ];
      volumes = [
        "/var/lib/${app.name}/conf:/opt/adguardhome/conf:rw"
        "/var/lib/${app.name}/work:/opt/adguardhome/work:rw"
      ];
      extraOptions = [
        "--network=${app.name}"
        "--ip=${app.containerIP}"
      ];
    };

    # Setup firewall exceptions
    #networking.firewall.interfaces.${app.name}.allowedTCPPorts = [
    #  ${app.port} 3000 53 # 67 68 443 853 5443 6060
    #];

    # Create host macvlan with a dedicated static IP to allow connections back to the container
    # from the host. This is for a different purpose that the other services.
    networking = {
      macvlans.${app.name} = {
        interface = "${app.nic}";
        mode = "bridge";
      };
      interfaces.${app.name}.ipv4.addresses = [
        { address = "${app.hostIP}"; prefixLength = 32; }
      ];

      # Setup route to containerIP
    };

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app.name}" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f ${app.name}";
      };
      script = ''
        podman network inspect ${app.name} || podman network create -d macvlan --subnet=${app.subnet} --gateway=${app.gateway} -o parent=${app.nic} ${app.name}
      '';
    };

    # Add additional configuration to the above generated app service unit i.e. acts as an overlay.
    # We simply match the name here that is autogenerated from the oci-container directive.
    systemd.services."podman-${app.name}" = {
      wantedBy = [ "multi-user.target" ];

      # Trigger the creation of the app macvlan if not already and wait for it. network-addresses...
      # applies the static IP address to the macvlan which it waits to be created for, thus by
      # waiting on it we ensure the macvlan is up and running with an IP address.
      wants = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];
      after = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app.name}";
      };
    };
  };
}
