# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.system.services.sshd;
in
{
  options = {
    system.services.sshd = {
      enable = lib.mkEnableOption "Install and configure openssh server";
      harden = lib.mkEnableOption "Apply recommended upstream security hardening to sshd";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      services.openssh.enable = true;

      users.motd = ''
      -----------------------------------------------------------------------------------------
                                                   |
                        |                        .$$
                        $$.                     .$$$
                        $$$.                    $$$$
                        $$$$                    $$$$
       -===============-$$$$-==================-$$$$-=========- -high tech, low life -=======-
                        $$$$                    $$$$
                        $$$$  ....        ..    $$$$  .### ..    .,,,    ,,'$$        $$$$$'
          .4$$$$$$$$$$. $$####|$$$B.4BBBBBBB$##|$$$$|B#### $$$$$$$$$$$ii $$$$3$      $$$$$
          $$$$$$$$$$$$$ $$####|4$$$B|BBBBBBBB##|$$$$|B'    9$$$P$$$9$$$$ $$$#$$$    $$$$$
          $$$$    ####' $$#### '4$$$$     ####  $$$$  $$$$ 0$$$  BB|$$$$ $$$#$$$$..$$$$$
          $$$$    ####  $$####   $$$$BBBBBBBBB  $$$$  $$$$ $$$$  $$|$$$$ $$$$ $$$$$$$$'
          $$$$    ####  $$####   $$$$BBBBBBBBB  $$$$  $$$$ $$$$  $$|$$$$ $$$$ '$$$$$$$
          $$$$    ###P  $$####   $$$E     ####  $$$$  $$$$ $$$$  $$|$$$E $$$$.$$$$$$$$$
          $$$$    ######$$#### .d$$$E     ####  $$$$  $$$$ $$$$  $$|$$$E3$$$$3$$$  $$$$$
      -==-$$$$$$$$$$$$$#######|B9$$'BBBBBBBBB$--$$$$--$$$$-$$$$--$$|$$$E3$$$|$$$-==-$$$$$-====-
       -=-'4$$$$$$$$$P-=-'####|BBP'9BVVVVVVVBV--$$$$--VVV'-VVVV--``'VVVV``$$$$$-====-$$$$$-==-
         -=======-.###########-==========-####--$$$'--'-===============-.$$$$$-======-$$$$$.TM
                  '##########'                  $$'  -phR0ze
                                                |

      '';
    })

    (lib.mkIf (cfg.enable && cfg.harden) {
      services.openssh.ports = [ 2222 ];                # cut down on automated scanning noise

      services.openssh.settings = {
        PermitRootLogin = "prohibit-password";          # root login only via key, never password
        PasswordAuthentication = false;                 # key-only auth for all users
        KbdInteractiveAuthentication = false;           # PAM can otherwise prompt for a password anyway
        X11Forwarding = false;                          # no GUI forwarding needed for a headless daemon
        LogLevel = "VERBOSE";                           # log the key fingerprint used on each auth attempt
      };

      # Turn on the shared CrowdSec engine (system.services.crowdsec) and feed it SSH-specific
      # detection - it already handles the generic engine/bouncer/profile/whitelist wiring.
      system.services.crowdsec.enable = true;

      services.crowdsec = {
        # linux transitively includes the sshd collection (sshd-logs/sshd-success-logs parsers plus
        # ssh-bf, ssh-slow-bf, ssh-time-based-bf, ssh-cve-2024-6387, ssh-refused-conn, ssh-generic-test)
        # and adds geoip/dateparse enrichment plus a good-actor whitelist (crawlers/CDNs/rDNS), so hub
        # updates can't leave one piece behind by hand-picking just sshd.
        hub.collections = [ "crowdsecurity/linux" ];

        localConfig = {
          acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
              labels.type = "syslog";
            }
          ];

          # The hub's crowdsecurity/ssh-bf ships with a liberal 5 failures/10s threshold. This adds
          # a tighter detector alongside it (not a replacement - both stay active) requiring only 3
          # failures, tolerated up to 30s apart, so slower/patient brute forcing gets caught too and
          # not just fast bursts.
          scenarios = [
            {
              type = "leaky";
              name = "local/ssh-bf-tight";
              description = "Detect ssh bruteforce with a tighter threshold than the hub default";
              filter = "evt.Meta.log_type == 'ssh_failed-auth'";
              groupby = "evt.Meta.source_ip";
              leakspeed = "30s";
              capacity = 3;
              blackhole = "1m";
              labels = {
                service = "ssh";
                confidence = 3;
                spoofable = 0;
                classification = [ "attack.T1110" ];
                label = "SSH Bruteforce (tight)";
                behavior = "ssh:bruteforce";
                remediation = true;
              };
            }
          ];
        };
      };
    })
  ];
}
