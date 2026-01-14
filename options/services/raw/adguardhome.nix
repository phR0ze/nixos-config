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
#   1. nix-shell -p apacheHttpd --run "htpasswd -nB <USER>"
#   2. Trim off the prefix <USER>: and store the remaining portion
#      e.g. $2y$05$x3123cn5Kcr/6JRpXfxXYulhrxSIVtTQvwYDzMgzba.bZ6cT78cwa
# - https://github.com/AdguardTeam/AdGuardHome/wiki/Configuration#password-reset
#
# ### Services
# - podman-adguard
# - podman-network-adguard
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  machine = config.machine;
  cfg = config.services.raw.adguardhome;

  # Generate compatible password for adguard
  passFile = pkgs.runCommandLocal "adguard-passwd" {} ''
    mkdir $out
    ${pkgs.apacheHttpd}/bin/htpasswd -cbB "$out/pass" "${machine.user.name}" "${machine.user.pass}"
  '';
  passStr = builtins.readFile "${passFile}/pass";
  pass = builtins.elemAt (builtins.match "${machine.user.name}:(.*)" passStr) 0;

  ipAddress = (f.toIP config.net.primary.ip).address;
in
{
  options = {
    services.raw.adguardhome = {
      enable = lib.mkEnableOption "Install and configure Adguard Home server";
    };
  };
 
  config = lib.mkIf cfg.enable {

    # Explicitly adding here as only the TCP port seems to be allowed in the service
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.adguardhome = {
      enable = true;
      host = ipAddress;
      openFirewall = true; # only opens TCP 53
      settings = {
        theme = "dark";
        users = [{
          name = machine.user.name;
          password = pass;
        }];
        dns = {
          bind_hosts = [
            ipAddress
          ];
          ratelimit = 0;
          upstream_dns = [
            "https://dns.cloudflare.com/dns-query"
          ];
          bootstrap_dns = [
            "1.1.1.1"
            "9.9.9.10"
          ];
          fallback_dns = [
            "https://dns10.quad9.net/dns-query"
          ];
        };
        filters = [
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
            name = "AdGuard DNS filter";
            id = 1;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
            name = "AdAway Default Blocklist";
            id = 2;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_59.txt";
            name = "AdGuard DNS Popup Hosts filter";
            id = 1733441346;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_53.txt";
            name = "AWAvenue Ads Rule";
            id = 1733441347;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt";
            name = "Dan Pollock's List";
            id = 1733441348;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_51.txt";
            name = "HaGeZi's Pro++ Blocklist";
            id = 1733441349;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt";
            name = "OISD Blocklist Big";
            id = 1733441350;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt";
            name = "Peter Lowe's Blocklist";
            id = 1733441351;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt";
            name = "Steven Black's List";
            id = 1733441352;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_39.txt";
            name = "Dandelion Sprout's Anti Push Notifications";
            id = 1733441353;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt";
            name = "Dandelion Sprout's Game Console Adblock List";
            id = 1733441354;
          }

          # Specific allow list for allowing some affiliate referral tracking to keep things working
          # for shopping sites.
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_45.txt";
            name = "HaGeZi's Allowlist Referral";
            id = 1733441355;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt";
            name = "Malicious URL Blocklist (URLHaus)";
            id = 1733441356;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt";
            name = "Perflyst and Dandelion Sprout's Smart-TV Blocklist";
            id = 1733441357;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_50.txt";
            name = "uBlock₀ filters – Badware risks";
            id = 1733441358;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt";
            name = "WindowsSpyBlocker - Hosts spy rules";
            id = 1733441359;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt";
            name = "The Big List of Hacked Malware Web Sites";
            id = 1733441360;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt";
            name = "Phishing URL Blocklist (PhishTank and OpenPhish)";
            id = 1733441361;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt";
            name = "Stalkerware Indicators List";
            id = 1733441362;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt";
            name = "Dandelion Sprout's Anti-Malware List";
            id = 1733441363;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt";
            name = "ShadowWhisperer's Malware List";
            id = 1733441364;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_55.txt";
            name = "HaGeZi's Badware Hoster Blocklist";
            id = 1733441365;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt";
            name = "Scam Blocklist by DurableNapkin";
            id = 1733441366;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_54.txt";
            name = "HaGeZi's DynDNS Blocklist";
            id = 1733441367;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt";
            name = "Phishing Army";
            id = 1733441368;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt";
            name = "HaGeZi's Threat Intelligence Feeds";
            id = 1733441369;
          }
          {
            enabled = true;
            url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt";
            name = "NoCoin Filter List";
            id = 1733441370;
          }
          {
            enabled = true;
            url = "https://v.firebog.net/hosts/Easylist.txt";
            name = "EasyList";
            id = 1733441371;
          }
          {
            enabled = true;
            url = "https://v.firebog.net/hosts/Easyprivacy.txt";
            name = "EasyPrivacy";
            id = 1733441372;
          }
          {
            enabled = true;
            url = "https://blocklistproject.github.io/Lists/adguard/porn-ags.txt";
            name = "Blocklist adult content";
            id = 1733441373;
          }
        ];
        whitelist_filters = [
          {
            enabled = true;
            url = "https://raw.githubusercontent.com/phR0ze/adguard-lists/refs/heads/main/allow/allow.txt";
            name = "phR0ze allows";
            id = 1757123023;
          }
        ];
        user_rules = [
          "# Ads/Tracking allowed by AdGuard"
          "||adservice.google.*^$important"
          "||adsterra.com^$important"
          "||amplitude.com^$important"
          "||analytics.edgekey.net^$important"
          "||analytics.twitter.com^$important"
          "||app.adjust.*^$important"
          "||app.*.adjust.com^$important"
          "||app.appsflyer.com^$important"
          "||doubleclick.net^$important"
          "||googleadservices.com^$important"
          "||guce.advertising.com^$important"
          "||metric.gstatic.com^$important"
          "||mmstat.com^$important"
          "||statcounter.com^$important"
          # Firefox telemetry
          "||firefox.settings.services.mozilla.com^$important"
          "||firefox-settings-attachments.cdn.mozilla.net^$important"
          # Asus Router
          "||epdg.epc.mnc260.mcc310.pub.3gppnetwork.org^$important"
          "||getpocket.cdn.mozilla.net^$important"
        ];

        # Don't even bother logging just drop them
        blocked_hosts = [
          "connections.brother.com" # phone home for brother printers
        ];

        filtering = {
          safe_search = {
            enabled = true;
            bing = true;
            duckduckgo = true;
            ecosia = true;
            google = true;
            pixabay = true;
            yandex = true;
            youtube = true;
          };
          rewrites = [
            {
              domain = "adguard.local";
              answer = ipAddress;
            }
          ];
          filtering_enabled = true;
          parental_enabled = true;
          safebrowsing_enabled = true;
          protection_enabled = true;
        };
        statistics = {
          # Increase retention to 90 days
          interval = "2160h";
        };
      };
    };
  };
}
