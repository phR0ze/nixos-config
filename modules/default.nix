# Declares the machine's `host` type and imports every module in the repo
#
# ### Features
# - Imports every `modules/*` subdirectory and all of `layers/`, so every option in the repo is
#   defined on every host. Importing applies nothing - each module's own `enable` gate does.
# - `host` is the central hub of host-level configuration, defaulting every field from the composed
#   `args` attribute set (root `args.nix` -> root `args.dec.yaml` -> `hosts/<name>/args.nix` ->
#   `hosts/<name>/args.dec.yaml`, see `flake.nix`'s `mergeArgs`).
#
# ### Defaults
# Defaults are handled differently at different levels in Nix
# - When no properties are set for 'host.user' then the defaults for that option are used.
# - When properties are set e.g. 'host.user.email' then the host.user defaults are not used
#   and instead the 'user.nix' sub module defaults are used. Because of this odd behavior we must
#   pass in the 'args' to each sub module as well so that all defaults are set at every level to
#   cover all the use cases.
#---------------------------------------------------------------------------------------------------
{ config, lib, args, f, ... }: with lib.types;
let
  cfg = config.host;
  host = args.host or {};

  nic0Defaults = {
    name = host.network.nic0.name or "";
    ip = host.network.nic0.ip or "";
    mac = host.network.nic0.mac or "";
    link = host.network.nic0.link or "";
    subnet = host.network.nic0.subnet or "";
    gateway = host.network.nic0.gateway or "";
    dns.primary = host.network.nic0.dns.primary or "";
    dns.fallback = host.network.nic0.dns.fallback or "";
    mapNameFromMAC = host.network.nic0.mapNameFromMAC or "";
  };
in
{
  # Read in all modules in all directories to make all module options available for opt in.
  imports = [
    ./apps
    ./devices
    ../layers
    ./services
    ./system
    ./virtualization
  ];

  options = {
    host = lib.mkOption {
      description = lib.mdDoc "Machine configuration definition";
      type = types.submodule {
        options = {
          id = lib.mkOption {
            description = lib.mdDoc "Machine id for /etc/machine-id";
            type = types.str;
            default = host.id or "";
          };

          name = lib.mkOption {
            description = lib.mdDoc "Hostname";
            type = types.str;
            default = host.name or "";
          };

          type = lib.mkOption {
            description = lib.mdDoc ''
              Descriptive capabilities of this machine. These are not mutually exclusive - a
              machine can carry more than one type.
            '';
            type = types.submodule {
              options = {
                vm = lib.mkEnableOption "Machine is a QEMU virtual machine guest";
              };
            };
            default = { };
          };

          desktop.xfce = lib.mkOption {
            description = lib.mdDoc ''
              Give this machine a full XFCE desktop, see `layers.xfce.desktop`. That layer chains
              the rest in on its own (`xfce.base` -> `console.desktop` -> `server` -> `core`), so
              this single flag is all a desktop host's args need.
            '';
            type = types.bool;
            default = host.desktop.xfce or false;
          };

          resolution = lib.mkOption {
            description = lib.mdDoc "Display resolution, see `virtualization.qemu.guest.resolution`";
            type = types.submodule {
              options = {
                x = lib.mkOption {
                  description = lib.mdDoc "Horizontal resolution in pixels";
                  type = types.int;
                  default = host.resolution.x or 0;
                };
                y = lib.mkOption {
                  description = lib.mdDoc "Vertical resolution in pixels";
                  type = types.int;
                  default = host.resolution.y or 0;
                };
              };
            };
            default = { };
            example = { x = 1920; y = 1080; };
          };

          autologin = lib.mkOption {
            description = lib.mdDoc "Automatically log the primary user in after boot, see `system.x11.autologin`";
            type = types.bool;
            default = host.autologin or false;
          };

          locale = lib.mkOption {
            description = lib.mdDoc "Locale to use for various identifiers";
            type = types.str;
            default = if (host.locale or "" == "") then "en_US.UTF-8" else host.locale;
          };

          timezone = lib.mkOption {
            description = lib.mdDoc "Timezone to use for various identifiers";
            type = types.str;
            default = if (host.timezone or "" == "") then "Etc/GMT" else host.timezone;
          };

          boot = {
            efi = lib.mkOption {
              description = lib.mdDoc "Whether this machine boots via EFI";
              type = types.bool;
              default = host.boot.efi or false;
            };

            mbr = lib.mkOption {
              description = lib.mdDoc "BIOS MBR boot device, see `devices.boot.mbr`";
              type = types.str;
              default = host.boot.mbr or "nodev";
              example = "/dev/sda";
            };
          };

          network = {

            nic0 = lib.mkOption {
              description = lib.mdDoc "Primary NIC options, see `devices.network.nic0`";
              type = types.submodule (import ./types/nic.nix { inherit lib; defaults = nic0Defaults; });
              default = nic0Defaults;
            };

            gateway = lib.mkOption {
              description = lib.mdDoc "Default gateway, see `devices.network.gateway`";
              type = types.str;
              default = host.network.gateway or "";
            };

            subnet = lib.mkOption {
              description = lib.mdDoc "Default subnet/CIDR, see `devices.network.subnet`";
              type = types.str;
              default = host.network.subnet or "";
            };

            domain = lib.mkOption {
              description = lib.mdDoc ''
                Domain name owned by this host, forwarded below to every service that needs to know
                the fleet's zone name (`services.native.caddy.baseDomain`,
                `services.native.vaultwarden.baseDomain`, `services.native.adguardhome.baseDomain`,
                `services.oci.pangolin.baseDomain`) so the literal zone stays out of tracked files.
              '';
              type = types.str;
              default = host.network.domain or "";
            };

            dns = {
              primary = lib.mkOption {
                description = lib.mdDoc "Primary DNS server, see `devices.network.dns.primary`";
                type = types.str;
                default = host.network.dns.primary or "";
              };

              fallback = lib.mkOption {
                description = lib.mdDoc "Fallback DNS server, see `devices.network.dns.fallback`";
                type = types.str;
                default = host.network.dns.fallback or "";
              };
            };

            allowList = lib.mkOption {
              description = lib.mdDoc ''
                Trusted management IPs/CIDRs exempted from both hardening mechanisms: the geo-filter
                (`devices.network.harden.geoblockAllowList`) and CrowdSec's ban engine
                (`services.native.crowdsec.allowlist`).
              '';
              type = types.listOf types.str;
              default = host.network.allowList or [ ];
            };
          };

          sopsFile = lib.mkOption {
            description = lib.mdDoc ''
              Path to this machine's sops-encrypted secrets file. Not sourced from `args` (secrets
              stay sops-encrypted on disk and can't flow through the `args` merge like plain data) -
              instead `lib/flake`'s `flake::decrypt_secrets` merges the shared root
              `secrets.enc.yaml` with this host's `hosts/<hostname>/secrets.enc.yaml` override into
              a transient staged `hosts/<hostname>/secrets.merged.enc.yaml` before every build.

              Resolution order (first that exists wins):
              1. `hosts/<hostname>/secrets.merged.enc.yaml` - the staged root+override merge
              2. `hosts/<hostname>/secrets.enc.yaml` - host override alone (no root to merge with)
              3. root `secrets.enc.yaml` - the fleet-shared file, for a host with no override

              An `.isolated` host (see `hosts/<hostname>/.isolated`) is limited to exactly its own
              `hosts/<hostname>/secrets.enc.yaml`: `flake::decrypt_secrets` returns early for it, so
              no merge is ever produced (candidate 1 could only ever match a stale leftover from
              before the host was isolated), and the fleet-shared root file (candidate 3) must never
              be read for it at all.
            '';
            type = types.nullOr types.path;
            default =
              let
                hostDir = ../hosts + "/${cfg.name}";
                isolated = builtins.pathExists (hostDir + "/.isolated");
                candidates = if isolated then [ (hostDir + "/secrets.enc.yaml") ] else [
                  (hostDir + "/secrets.merged.enc.yaml")
                  (hostDir + "/secrets.enc.yaml")
                  ../secrets.enc.yaml
                ];
                found = lib.filter builtins.pathExists candidates;
              in if cfg.name != "" && found != [ ] then lib.head found else null;
          };

          nix.stateVersion = lib.mkOption {
            description = lib.mdDoc ''
              NixOS release this host was *first installed* with, see `system.env.nix.stateVersion`
              and upstream `system.stateVersion`. Never bump it on an existing host to match the
              nixpkgs being built - it exists precisely to keep stateful defaults (database
              versions, service data layouts) at what that host's on-disk state was created for.
            '';
            type = types.str;
            default =
              let v = host.nix.stateVersion or "";
              in if v == "" then lib.trivial.release else v;
            example = "25.05";
          };

          git = {
            user = lib.mkOption {
              description = lib.mdDoc "Git user name for flake management";
              type = types.str;
              default = host.git.user or "";
            };

            email = lib.mkOption {
              description = lib.mdDoc "Git user email for flake management";
              type = types.str;
              default = host.git.email or "";
            };
          };

          users.root.authorizedKeys = lib.mkOption {
            description = lib.mdDoc "SSH authorized keys for the root user";
            type = types.listOf types.str;
            default = host.users.root.authorizedKeys or [ ];
          };

          services = lib.mkOption {
            description = lib.mdDoc ''
              Raw `services.<namespace>.<name>.*` overrides sourced from `host.services` (i.e.
              `args`/`args.nix`/`args.enc.yaml`), keyed the same way as the real option path minus
              the leading `services.` - e.g. `oci.pangolin.baseDomain`. Lets a host's build-time
              args populate a real `services.<namespace>.<name>` option without hardcoding the
              value directly in that host's `configuration.nix`. Only fields this module's config
              section explicitly looks for (see below) are actually applied - anything else here
              is inert.
            '';
            type = types.attrsOf types.anything;
            default = host.services or { };
          };
        };
      };
      default = { };
    };
  };

  # Unlike prior renditions of this concept we'll explicitly and direclty apply overrides to the
  # configuration here rather than from special args being passed into all modules.
  #
  # - `config` block translates each selection directly into the real underlying NixOS option it
  #   implements - the goal is one place where
  # - the goals is that user install time or user configured overrides become the configuration
  # ------------------------------------------------------------------------------------------------
  config = lib.mkMerge [
    {
      devices.boot.efi = cfg.boot.efi;
      devices.boot.mbr = cfg.boot.mbr;
      networking.hostName = cfg.name;
      system.env.machineId = cfg.id;
      system.env.locale = cfg.locale;
      system.env.timezone = cfg.timezone;
      system.env.nix.stateVersion = cfg.nix.stateVersion;
      apps.system.git.user = cfg.git.user;
      apps.system.git.email = cfg.git.email;
      system.users.sopsFile = cfg.sopsFile;
      devices.network.gateway = cfg.network.gateway;
      devices.network.subnet = cfg.network.subnet;
      devices.network.dns.primary = cfg.network.dns.primary;
      devices.network.dns.fallback = cfg.network.dns.fallback;
      devices.network.nic0.name = cfg.network.nic0.name;
      devices.network.nic0.ip = cfg.network.nic0.ip;
      devices.network.nic0.mapNameFromMAC = cfg.network.nic0.mapNameFromMAC;
      devices.network.harden.geoblockAllowList = cfg.network.allowList;
      users.users.root.openssh.authorizedKeys.keys = cfg.users.root.authorizedKeys;
    }

    (lib.mkIf cfg.desktop.xfce {
      layers.xfce = {
        desktop.enable = true;
        base.autologin = cfg.autologin;
        base.resolution = { inherit (cfg.resolution) x y; };
      };
    })
    (lib.mkIf config.system.x11.enable {
      system.x11.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf cfg.type.vm {
      virtualization.qemu.guest.enable = true;
      virtualization.qemu.guest.hostname = cfg.name;
      # Only forward an explicitly set resolution; a 0x0 default would otherwise clobber
      # virtualization.qemu.guest.resolution's own 1920x1080 default.
      virtualization.qemu.guest.resolution = lib.mkIf (cfg.resolution.x != 0 && cfg.resolution.y != 0)
        { inherit (cfg.resolution) x y; };
      virtualization.qemu.guest.bridge = config.devices.network.bridge.name;
    })

    (lib.mkIf config.apps.network.rustdesk.enable {
      apps.network.rustdesk.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf config.apps.games.prismlauncher.enable {
      apps.games.prismlauncher.hostname = cfg.name;
    })

    (lib.mkIf config.services.native.smb.enable (
      let arg = f.getSvcFunc "native.smb" cfg.services;
      in {
        services.native.smb = {
          sopsFile = cfg.sopsFile;
          user = arg "user";
          pass = arg "pass";
          domain = arg "domain";
          dirMode = arg "dirMode";
          fileMode = arg "fileMode";
          entries = arg "entries";
        };
      }
    ))

    (lib.mkIf config.services.native.nfs.enable (
      let arg = f.getSvcFunc "native.nfs" cfg.services;
      in {
        services.native.nfs = {
          fsType = arg "fsType";
          options = arg "options";
          entries = arg "entries";
        };
      }
    ))

    (lib.mkIf config.services.native.caddy.enable (
      let arg = f.getSvcFunc "native.caddy" cfg.services;
      in {
        services.native.caddy.sopsFile = cfg.sopsFile;
        services.native.caddy.baseDomain = cfg.network.domain;
        services.native.caddy.proxies = arg "proxies";
      }
    ))

    (lib.mkIf config.services.native.vaultwarden.enable {
      services.native.vaultwarden.sopsFile = cfg.sopsFile;
      services.native.vaultwarden.baseDomain = cfg.network.domain;
    })

    (lib.mkIf config.services.native.adguardhome.enable {
      services.native.adguardhome.sopsFile = cfg.sopsFile;
      services.native.adguardhome.baseDomain = cfg.network.domain;
    })

    (lib.mkIf config.services.native.alerts.enable {
      services.native.alerts.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf config.services.native.crowdsec.enable {
      services.native.crowdsec.sopsFile = cfg.sopsFile;
      services.native.crowdsec.allowlist = cfg.network.allowList;
    })

    (lib.mkIf config.services.oci.pangolin.enable (
      let arg = f.getSvcFunc "oci.pangolin" cfg.services;
      in {
        services.oci.pangolin.sopsFile = cfg.sopsFile;
        services.oci.pangolin.baseDomain = cfg.network.domain;
        services.oci.pangolin.acmeEmail = arg "acmeEmail";
        services.oci.pangolin.geoblockAllowList = cfg.network.allowList;
      }
    ))
  ];
}
