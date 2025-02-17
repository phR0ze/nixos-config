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
#
# ### Password reset
# - Generate new password: mkpasswd -m bcrypt -R 10 <super-strong-password>
# - https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#password-reset
#
# ### Services
# - podman-adguard
# - podman-network-adguard
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.homelab.adguard;
  app = config.homelab.adguard.app;
  appOpts = (import ../types/app.nix { inherit lib; }).appOpts;

  configFile = pkgs.writeTextFile {
    name = "AdGuardHome.yaml";
    text = ''
      theme: dark
      dns:
        upstream_dns:
          - https://dns.cloudflare.com/dns-query
        bootstrap_dns:
          - 1.1.1.1
          - 8.8.8.8
        fallback_dns:
          - https://dns.google/dns-query
      filters:
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
          name: AdGuard DNS filter
          id: 1
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt
          name: AdAway Default Blocklist
          id: 2
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt
          name: AdGuard DNS Popup Hosts filter
          id: 1733441346
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt
          name: AWAvenue Ads Rule
          id: 1733441347
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt
          name: Dan Pollock's List
          id: 1733441348
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt
          name: HaGeZi's Pro++ Blocklist
          id: 1733441349
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
          name: OISD Blocklist Big
          id: 1733441350
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt
          name: Peter Lowe's Blocklist
          id: 1733441351
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt
          name: Steven Black's List
          id: 1733441352
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt
          name: Dandelion Sprout's Anti Push Notifications
          id: 1733441353
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt
          name: Dandelion Sprout's Game Console Adblock List
          id: 1733441354
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt
          name: HaGeZi's Allowlist Referral
          id: 1733441355
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
          name: Malicious URL Blocklist (URLHaus)
          id: 1733441356
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt
          name: Perflyst and Dandelion Sprout's Smart-TV Blocklist
          id: 1733441357
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt
          name: uBlock₀ filters – Badware risks
          id: 1733441358
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt
          name: WindowsSpyBlocker - Hosts spy rules
          id: 1733441359
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt
          name: The Big List of Hacked Malware Web Sites
          id: 1733441360
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt
          name: Phishing URL Blocklist (PhishTank and OpenPhish)
          id: 1733441361
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt
          name: Stalkerware Indicators List
          id: 1733441362
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt
          name: Dandelion Sprout's Anti-Malware List
          id: 1733441363
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt
          name: ShadowWhisperer's Malware List
          id: 1733441364
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt
          name: HaGeZi's Badware Hoster Blocklist
          id: 1733441365
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt
          name: Scam Blocklist by DurableNapkin
          id: 1733441366
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt
          name: HaGeZi's DynDNS Blocklist
          id: 1733441367
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt
          name: Phishing Army
          id: 1733441368
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt
          name: HaGeZi's Threat Intelligence Feeds
          id: 1733441369
        - enabled: true
          url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt
          name: NoCoin Filter List
          id: 1733441370
        - enabled: true
          url: https://v.firebog.net/hosts/Easylist.txt
          name: EasyList
          id: 1733441371
        - enabled: true
          url: https://v.firebog.net/hosts/Easyprivacy.txt
          name: EasyPrivacy
          id: 1733441372
        - enabled: true
          url: https://blocklistproject.github.io/Lists/adguard/porn-ags.txt
          name: Blocklist adult content
          id: 1733441373
      whitelist_filters: []
      user_rules:
        - '# Ads/Tracking allowed by AdGuard'
        - '||adservice.google.*^$important'
        - '||adsterra.com^$important'
        - '||amplitude.com^$important'
        - '||analytics.edgekey.net^$important'
        - '||analytics.twitter.com^$important'
        - '||app.adjust.*^$important'
        - '||app.*.adjust.com^$important'
        - '||app.appsflyer.com^$important'
        - '||doubleclick.net^$important'
        - '||googleadservices.com^$important'
        - '||guce.advertising.com^$important'
        - '||metric.gstatic.com^$important'
        - '||mmstat.com^$important'
        - '||statcounter.com^$important'
        - ""
      filtering:
        safe_search:
          enabled: true
          bing: true
          duckduckgo: true
          ecosia: true
          google: true
          pixabay: true
          yandex: true
          youtube: true
        rewrites: []
        filtering_enabled: true
        parental_enabled: true
        safebrowsing_enabled: true
        protection_enabled: true
    '';
  };
in
{
  options = {
    homelab.adguard = {
      enable = lib.mkEnableOption "Deploy container based Adguard Home";

      app = lib.mkOption {
        description = lib.mdDoc "Containerized app options";
        type = types.submodule appOpts;
        default = {
          name = "adguard";
          user = {
            name = machine.user.name;
            uid = config.users.users.${machine.user.name}.uid;
            gid = config.users.groups."users".gid;
          };
          nic = {
            name = machine.nic0.name;
            subnet = machine.nic0.subnet;
            gateway = machine.nic0.gateway;
            ip = "192.168.1.52";  # Host IP
            port = 80;            # Web interface ip
          };
        };
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (app.name != null && app.name != "");
        message = "Application name not specified, please set 'app.name'"; }
      { assertion = (app.user.name != null && app.user.name != "");
        message = "Application user name not specified, please set 'app.user.name'"; }
      { assertion = (app.user.uid != null);
        message = "Application user uid not specified, please set 'app.user.uid'"; }
      { assertion = (app.user.gid != null);
        message = "Application user gid not specified, please set 'app.user.gid'"; }
      { assertion = (app.nic.name != null && app.nic.name != "");
        message = "Application parent NIC not specified, please set 'app.nic.name'"; }
      { assertion = (app.nic.subnet != null && app.nic.subnet != "");
        message = "Network subnet not specified, please set 'app.nic.subnet'"; }
      { assertion = (app.nic.gateway != null && app.nic.gateway != "");
        message = "Network gateway not specified, please set 'app.nic.gateway'"; }
      { assertion = (app.nic.ip != null && app.nic.ip != "");
        message = "Host macvlan IP not specified, please set 'app.nic.ip'"; }
      { assertion = (app.nic.port != null && app.nic.port != "");
        message = "Nic port not specified, please set 'app.nic.port'"; }
    ];

    # Requires podman virtualization to be configured
    virtualisation.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/conf 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/work 0750 ${toString app.user.uid} ${toString app.user.gid} -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # https://github.com/AdguardTeam/AdGuardHome/wiki/Docker
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/adguard/adguardhome:latest";
      autoStart = true;
      hostname = "${app.name}";
      # No need for port forwarding as were using a macvlan to expose the service directly
#      ports = [
#        "${app.nic.ip}:53:53/tcp" "${app.nic.ip}:53:53/udp"         # plain DNS
#        "${app.nic.ip}:${toString app.nic.port}:80/tcp"             # web interface
#        "${app.nic.ip}:3000:3000/tcp"                           # setup web interface
#        #"${app.nic.ip}:67:67/udp" "${app.nic.ip}:68:68/udp"         # add if using as DHCP server
#        #"${app.nic.ip}:443:443/tcp" "${app.nic.ip}:443:443/udp"     # add if using as HTTPS/DNS over HTTPS server
#        #"${app.nic.ip}:853:853/tcp"                             # add if using as DNS over TLS server
#        #"${app.nic.ip}:853:853/udp"                             # add if using as DNS over QUIC server
#        #"${app.nic.ip}:5443:5443/tcp" "${app.nic.ip}:5443:5443/udp" # add if using AdGuard as DNSCrypt server
#        #"${app.nic.ip}:6060:6060/tcp"                           # debugging profiles
#      ];
      volumes = [
        "/var/lib/${app.name}/conf:/opt/adguardhome/conf:rw"
        "/var/lib/${app.name}/work:/opt/adguardhome/work:rw"
      ];
      extraOptions = [
        "--network=${app.name}"
        "--ip=${app.nic.ip}"
      ];
    };

    # No need for firewall exceptions because the macvlan is exposed directly on the LAN
    #networking.firewall.interfaces."${app.name}".allowedTCPPorts = [
    #  ${app.nic.port} 3000 53 # 67 68 443 853 5443 6060
    #];

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app.name}" = {
      path = [ pkgs.podman pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = [
          "podman network rm -f ${app.name}"
          "ip route del ${app.nic.ip} dev ${config.networking.bridge.macvlan.name} &>/dev/null || true"
        ];
      };
      script = ''
        if ! podman network exists ${app.name}; then
          podman network create -d macvlan --subnet=${app.nic.subnet} --gateway=${app.nic.gateway} -o parent=${app.nic.name} ${app.name}
        fi

        # Setup host to container access by adding an explicit route
        ip route add ${app.nic.ip2} dev ${app.name} &>/dev/null || true
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

      # Merge in the persisted configuration file
      preStart = ''
        if [ "${f.boolToIntStr app.configure}" = "1" ]; then
          if [ -e "/var/lib/${app.name}/conf/AdGuardHome.yaml" ]; then
            ${pkgs.yaml-merge}/bin/yaml-merge "/var/lib/${app.name}/conf/AdGuardHome.yaml" "${configFile}" > "/var/lib/${app.name}/conf/AdGuardHome.yaml.tmp"
            # Writing directly to AdGuardHome.yaml seems to result in an empty file
            mv "/var/lib/${app.name}/conf/AdGuardHome.yaml.tmp" "/var/lib/${app.name}/conf/AdGuardHome.yaml"
          else
            cp --force "${configFile}" "/var/lib/${app.name}/conf/AdGuardHome.yaml"
            chmod 600 "/var/lib/${app.name}/conf/AdGuardHome.yaml"
          fi
        fi
      '';

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app.name}";
      };
    };
  };
}
