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
      # there - instead this runs on every interactive shell, right after sshd prints /etc/motd and
      # before the user's prompt, giving the same "below my existing motd" placement. Guarded to SSH
      # sessions only so local console/desktop shells don't get it too, and to SHLVL == 1 so it
      # only fires on the actual login shell - nix-shell, sudo -i, or a plain nested bash all
      # inherit SSH_CONNECTION from the environment and would otherwise reprint it on every
      # subshell spawned inside an already-logged-in session.
      #
      # Deliberately NOT environment.etc."profile.d/*.sh": plain NixOS's generated /etc/profile and
      # /etc/bashrc never loop over /etc/profile.d/*.sh (that's a Fedora/Debian convention, not
      # something NixOS wires up for arbitrary environment.etc files) - a script placed there is
      # simply never sourced (confirmed live on hosts/vps1: the file existed verbatim but /etc/profile
      # and /etc/bashrc had no reference to it). environment.interactiveShellInit genuinely is
      # concatenated into /etc/bashrc's `if [ -n "$PS1" ]` block regardless of shell customization.
      environment.interactiveShellInit = ''
        # shellcheck shell=bash
        if [ -n "$SSH_CONNECTION" ] && [ -n "$PS1" ] && [ "$SHLVL" -eq 1 ]; then
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

          # Only emit color codes to an actual terminal - keeps piped/logged output (e.g. a
          # session captured to a file) free of escape sequences.
          if [ -t 1 ]; then
            c_label="\033[1;36m"  # bold cyan
            c_header="\033[1;33m" # bold yellow
            c_reset="\033[0m"
          else
            c_label=""
            c_header=""
            c_reset=""
          fi

          printf '\n'
          printf "''${c_header}%s''${c_reset}\n" "$host"
          printf " - ''${c_label}Host:''${c_reset}  %-24s %s\n" "$os_pretty" "Linux $kernel"
          printf " - ''${c_label}CPU:''${c_reset}   %-45s %s\n" "$cpu_model" "$cpu_topology"
          printf " - ''${c_label}RAM:''${c_reset}   %-24s %-20s %s swap\n" "$ram" "$mem_pct used" "$swap_pct"
          printf " - ''${c_label}Disk:''${c_reset}  %-24s %s\n" "$boot" "$root_use of $root_size used"
          printf " - ''${c_label}Load:''${c_reset}  %-24s %-20s %s %s\n" "$load" "$procs procs" "$users" "$user_label"
          printf " - ''${c_label}IPv4:''${c_reset}  %-24s %s\n" "''${ipv4:-unknown}" "''${iface:-eth0}"
          printf '\n'
        fi
      '';
    })

    (lib.mkIf (cfg.enable && cfg.harden) {
      services.openssh.ports = [ 2222 ];                # cut down on automated scanning noise

      # Open the port ourselves via a rate-limited nftables rule below instead of letting openssh's
      # module add an unconditional accept for it - see extraInputRules.
      services.openssh.openFirewall = false;

      services.openssh.settings = {
        PermitRootLogin = "prohibit-password";          # root login only via key, never password
        PasswordAuthentication = false;                 # key-only auth for all users
        KbdInteractiveAuthentication = false;           # PAM can otherwise prompt for a password anyway
        X11Forwarding = false;                          # no GUI forwarding needed for a headless daemon
        LogLevel = "VERBOSE";                           # log the key fingerprint used on each auth attempt

        # Resource-abuse hardening: bound how much CPU/memory a flood of connection attempts can
        # cost before any of them are even authenticated.
        MaxAuthTries = 3;                                # default 6 - fewer guesses per connection
        LoginGraceTime = 20;                             # default 120s - drop slow/half-open auth attempts fast
        MaxStartups = "10:30:60";                        # start randomly dropping at 10 unauthenticated
                                                          # conns (30% probability), hard cap at 60

        # This host has no need for SSH as a transport for anything but an interactive/admin shell -
        # disable the forwarding features that a compromised or probing client could otherwise abuse.
        AllowTcpForwarding = false;
        AllowAgentForwarding = false;
        GatewayPorts = "no";
        PermitTunnel = "no";

        # Drop dead/hung sessions instead of leaving them to hold a slot indefinitely.
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };

      # sshd's own accept-all-comers rule is replaced with this: cap new connections to the SSH port
      # per-source before they cost a fork()+key-exchange. Excess (over-rate) SYNs simply don't match
      # here and fall through to the generic `input` chain - `logRefusedConnections` still logs them
      # (so CrowdSec's ssh-bf/port-scan scenarios keep full visibility) and the chain's own `policy
      # drop` still discards them; only the accept path skips them.
      networking.firewall.extraInputRules = ''
        tcp dport 2222 ct state new limit rate 15/minute burst 5 packets accept
      '';

      systemd.services.sshd.serviceConfig = {
        # ProtectSystem intentionally NOT "full"/"strict": this mount-namespace restriction is
        # inherited by every login session's shell (same inheritance mechanism as RestrictNamespaces
        # below), making /etc (and thus /etc/nixos, this repo's own checkout) read-only for every SSH
        # session including root - `git pull`/`clu update` themselves are blocked ("Read-only file
        # system" writing .git/FETCH_HEAD, confirmed live on hosts/vps1). Remote `git pull`/`clu
        # update` is how this host gets managed at all, so this hardening knob is traded away same as
        # the others below. Leaving ProtectHome/ProtectKernel*/etc. below in place - those are
        # unaffected by this since they don't cover paths the admin workflow needs to write.
        ProtectSystem = false;
        ProtectHome = false;              # PAM modules (motd/lastlog) commonly touch home-adjacent paths
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        # ProtectKernelLogs intentionally NOT set: this restriction is inherited by every login
        # session's shell (same inheritance mechanism as RestrictNamespaces below) and blocks `dmesg`
        # outright for root over SSH - redundant anyway since devices.kernel.harden's
        # kernel.dmesg_restrict=1 sysctl already restricts kernel log access to CAP_SYSLOG at the
        # kernel level. Normal remote diagnostics over SSH is a routine part of managing this host.
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        # MemoryDenyWriteExecute intentionally NOT set: this seccomp restriction is inherited by
        # every login session's shell (same inheritance mechanism as RestrictNamespaces below) and
        # blocks any JIT compiler run over SSH from creating writable+executable pages - neovim's
        # bundled LuaJIT panics with "runtime code generation failed, restricted kernel?" the moment
        # it starts (confirmed live on hosts/vps1). Interactive admin tooling over SSH is a normal
        # part of managing a headless VPS, so this hardening knob is traded away same as the two below.

        # AF_NETLINK included alongside AF_INET/AF_UNIX (IPv6 disabled fleet-wide already) - without
        # it, this seccomp restriction is inherited by every login session's shell (same mechanism
        # as RestrictNamespaces below) and silently breaks any netlink-based tool run over SSH -
        # `ip`, `ss`, `nft` (an admin's own interactive commands, not crowdsec-firewall-bouncer's
        # own systemd unit, which is sandboxed separately in crowdsec.nix) all fail with "Cannot
        # open netlink socket: Address family not supported by protocol" (confirmed via a local
        # quickemu VM test). Basic network diagnostics/firewall admin is a normal part of managing a
        # VPS remotely, so AF_NETLINK stays allowed rather than dropping the whole restriction -
        # AF_PACKET included alongside these for the same reason: `tcpdump`/other raw packet capture
        # tools are a routine part of remote diagnostics on a headless VPS, and without it they fail
        # to open a capture socket the moment they're run over SSH (same inheritance mechanism as
        # RestrictNamespaces below).
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" "AF_NETLINK" "AF_PACKET" ];
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
      # detection - it already handles the generic engine/bouncer/profile/allowlist wiring.
      services.native.crowdsec.enable = true;

      services.crowdsec = {
        # linux transitively includes the sshd collection (sshd-logs/sshd-success-logs parsers plus
        # ssh-bf, ssh-slow-bf, ssh-time-based-bf, ssh-cve-2024-6387, ssh-refused-conn, ssh-generic-test)
        # and adds geoip/dateparse enrichment plus a good-actor allowlist (crawlers/CDNs/rDNS), so hub
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
