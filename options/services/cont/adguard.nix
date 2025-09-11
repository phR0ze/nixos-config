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
# - Generate new password
#   1. nix-shell -p apacheHttpd
#   2. htpasswd -nB <USER>
#   3. Store the value minus the user name prefix e.g. admin:$2y$05$xGiz3cn5Kcr/6JRpXfxXYulhrxSIVtTQvwYDzMgzba.bZ6cT78cwa
#      in the services.cont.adguard.user.pass = $2y$05$xGiz3cn5Kcr/6JRpXfxXYulhrxSIVtTQvwYDzMgzba.bZ6cT78cwa
# - https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#password-reset
#
# ### Services
# - podman-adguard
# - podman-network-adguard
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.adguard;
  defaults = f.getService args "adguard" 2003 2003;
  ipaddr = (f.toIP machine.net.nic.ip).address;

  # Note: the contents of this file can be created by setting the 'configure=false;' flag then 
  # manually configuring Adguard via the UI then checking the resulting /var/lib/adguard/conf/AdGuardHome.yaml
  configFile = pkgs.writeTextFile {
    name = "AdGuardHome.yaml";
    text = ''
      theme: dark
      dns:
        ratelimit: 0
        upstream_dns:
          - https://dns.cloudflare.com/dns-query
        bootstrap_dns:
          - 1.1.1.1
          - 9.9.9.10
        fallback_dns:
          - https://dns10.quad9.net/dns-query
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
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.cont.adguard = lib.mkOption {
      description = lib.mdDoc "Adguard service options";
      type = types.submodule {
        options = {
          configure = lib.mkOption {
            description = lib.mdDoc "Include the persisted configuration";
            type = types.bool;
            default = false;
          };
        };
        imports = [
          (import ../../types/service.nix { inherit lib defaults; })
        ];
      };
      default = defaults;
    };
  };
 
  config = lib.mkIf cfg.enable {

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/conf 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/work 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    # https://github.com/AdguardTeam/AdGuardHome/wiki/Docker
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "docker.io/adguard/adguardhome:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      ports = [
        "${ipaddr}:53:53/tcp" "${ipaddr}:53:53/udp"         # plain DNS
        "${ipaddr}:${toString cfg.port}:80/tcp"             # web interface
        "${ipaddr}:3000:3000/tcp"                           # setup web interface
#        "${ipaddr}:67:67/udp" "${ipaddr}:68:68/udp"         # add if using as DHCP server
#        "${ipaddr}:443:443/tcp" "${ipaddr}:443:443/udp"     # add if using as HTTPS/DNS over HTTPS server
#        "${ipaddr}:853:853/tcp"                             # add if using as DNS over TLS server
#        "${ipaddr}:853:853/udp"                             # add if using as DNS over QUIC server
#        "${ipaddr}:5443:5443/tcp" "${ipaddr}:5443:5443/udp" # add if using AdGuard as DNSCrypt server
#        "${ipaddr}:6060:6060/tcp"                           # debugging profiles
      ];
      volumes = [
        "/var/lib/${cfg.name}/conf:/opt/adguardhome/conf:rw"
        "/var/lib/${cfg.name}/work:/opt/adguardhome/work:rw"
      ];
      extraOptions = [
        "--network=${cfg.name}"
      ];
    };

    # Additional firewall exceptions
    networking.firewall.interfaces.${machine.net.nic.name}.allowedTCPPorts = [
      cfg.port 3000 53 # 67 68 443 853 5443 6060
    ];

    # Merge in the persisted configuration file using the same generated service unit name
    systemd.services."podman-${cfg.name}" = {
      preStart = ''
        if [ "${f.boolToIntStr cfg.configure}" = "1" ]; then
          if [ -e "/var/lib/${cfg.name}/conf/AdGuardHome.yaml" ]; then
            ${pkgs.yaml-merge}/bin/yaml-merge "/var/lib/${cfg.name}/conf/AdGuardHome.yaml" "${configFile}" > "/var/lib/${cfg.name}/conf/AdGuardHome.yaml.tmp"
            # Writing directly to AdGuardHome.yaml seems to result in an empty file
            mv "/var/lib/${cfg.name}/conf/AdGuardHome.yaml.tmp" "/var/lib/${cfg.name}/conf/AdGuardHome.yaml"
          else
            cp --force "${configFile}" "/var/lib/${cfg.name}/conf/AdGuardHome.yaml"
            chmod 600 "/var/lib/${cfg.name}/conf/AdGuardHome.yaml"
          fi
        fi
      '';
    };
  };
}
