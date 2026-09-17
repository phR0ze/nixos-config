# SSHD configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.services.native.sshd;
in
{
  options = {
    services.native.sshd = {
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

      # Dynamic system-info block, printed below the static ASCII motd above. /etc/motd itself is
      # static (rendered once at build time), so live values (load, memory, IP, ...) can't live
      # there - instead this sources on every interactive SSH login shell, right after sshd prints
      # /etc/motd and before the user's prompt, giving the same "below my existing motd" placement.
      # Guarded to SSH sessions only so local console/desktop shells don't get it too.
      environment.etc."profile.d/motd-sysinfo.sh".text = ''
        # shellcheck shell=bash
        if [ -n "$SSH_CONNECTION" ] && [ -n "$PS1" ]; then
          load="$(cut -d' ' -f1-3 /proc/loadavg)"
          procs="$(ps ax --no-headers | wc -l)"
          users="$(who | wc -l)"
          user_label="users"
          [ "$users" = "1" ] && user_label="user"

          root_use="$(df -h --output=pcent,size / | tail -1 | awk '{print $1}')"
          root_size="$(df -h --output=pcent,size / | tail -1 | awk '{print $2}')"

          mem_pct="$(free | awk '/^Mem:/ {printf "%.0f%%", $3/$2*100}')"
          swap_total="$(free | awk '/^Swap:/ {print $2}')"
          swap_pct="0%"
          [ "$swap_total" -gt 0 ] 2>/dev/null && swap_pct="$(free | awk '/^Swap:/ {printf "%.0f%%", $3/$2*100}')"

          iface="$(ip -4 --color=never route show default 2>/dev/null | awk '{print $5; exit}')"
          ipv4="$(ip -4 -o --color=never addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1)"

          os_pretty="$(. /etc/os-release; echo "$PRETTY_NAME")"
          kernel="$(uname -r)"
          host="$(hostname)"

          cpu_model="$(lscpu | awk -F': +' '/^Model name:/ {print $2; exit}')"
          virt="$(systemd-detect-virt 2>/dev/null)"
          virt="''${virt:-none}"
          sockets="$(lscpu | awk -F': +' '/^Socket\(s\):/ {print $2; exit}')"
          cores="$(lscpu | awk -F': +' '/^Core\(s\) per socket:/ {print $2; exit}')"
          threads="$(lscpu | awk -F': +' '/^Thread\(s\) per core:/ {print $2; exit}')"

          ram="$(free -h | awk '/^Mem:/ {print $2}')"

          if [ -d /sys/firmware/efi ]; then
            boot="UEFI"
          else
            boot="BIOS"
          fi

          cpu_topology="''${sockets}S/''${cores}C/''${threads}T"
          [ "$virt" != "none" ] && cpu_topology="$cpu_topology, $virt"

          printf ' - Host:  %-24s %-20s %s\n' "$os_pretty" "Linux $kernel" "$host"
          printf ' - CPU:   %-45s %s\n' "$cpu_model" "$cpu_topology"
          printf ' - RAM:   %-24s %-20s %s swap\n' "$ram" "$mem_pct used" "$swap_pct"
          printf ' - Disk:  %-24s %s\n' "$boot" "$root_use of $root_size used"
          printf ' - Load:  %-24s %-20s %s %s\n' "$load" "$procs procs" "$users" "$user_label"
          printf ' - IPv4:  %-24s %s\n' "''${ipv4:-unknown}" "''${iface:-eth0}"
          printf '\n'
        fi
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

      systemd.services.sshd.serviceConfig = {
        ProtectSystem = "full";           # read-only /usr,/boot,/etc; /var,/run stay writable (sshd needs these)
        ProtectHome = false;              # PAM modules (motd/lastlog) commonly touch home-adjacent paths
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        MemoryDenyWriteExecute = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];   # IPv6 disabled fleet-wide already
        # NoNewPrivileges intentionally NOT set: sshd forks per-connection children that setuid to
        # the logging-in user, which NoNewPrivileges=true blocks and would break every login.

        # RestrictNamespaces intentionally NOT set: sandboxing directives on sshd.service apply
        # (via seccomp) to every process descending from it, including each login session's shell -
        # RestrictNamespaces=true silently breaks unshare()/`nix build`'s sandboxed builds for
        # anyone administering the box over SSH (confirmed via a local quickemu VM test: `nix build`
        # works fine locally at the console but fails "this system does not support the kernel
        # namespaces that are required for sandboxing" the moment it's run over SSH). That defeats
        # the primary admin workflow on a headless VPS - remote `nixos-rebuild`/`clu update` is how
        # this host gets managed at all, so trade this one hardening knob for a working remote build.
      };

      # Turn on the shared CrowdSec engine (services.native.crowdsec) and feed it SSH-specific
      # detection - it already handles the generic engine/bouncer/profile/whitelist wiring.
      services.native.crowdsec.enable = true;

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
