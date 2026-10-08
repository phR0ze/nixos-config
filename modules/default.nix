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

  # Args-supplied xfce desktop variant selections, e.g. `host.desktop.xfce.standard = true`
  xfce = host.desktop.xfce or {};

  # Forwards the `services.oci.<name>.*` fields every OCI module shares (declared by
  # modules/types/service.nix) from this host's args, exactly the way the native services below
  # are forwarded one field at a time - the set is identical for all of them, so it's expressed
  # once here rather than repeated per service. `f.getSvcFunc` yields a `mkIf`-guarded no-op for
  # any field the args don't set, leaving the module's own default in place.
  ociForward = name: let
    arg = f.getSvcFunc "oci.${name}" cfg.services;
  in {
    sopsFile = cfg.sopsFile;
    name = arg "name";
    tag = arg "tag";
    user = arg "user";
    port = arg "port";
    caddy = arg "caddy";
    subdomain = arg "subdomain";
    subnet = arg "subnet";
    ip = arg "ip";
  };

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

  dnsDefaults = {
    primary = host.network.dns.primary or null;
    fallback = host.network.dns.fallback or null;
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
      description = "Machine configuration definition";
      type = types.submodule {
        options = {
          id = lib.mkOption {
            description = "Machine id for /etc/machine-id";
            type = types.str;
            default = host.id or "";
          };

          name = lib.mkOption {
            description = "Hostname";
            type = types.str;
            default = host.name or "";
          };

          type = lib.mkOption {
            description = ''
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
            description = ''
              Give this machine an XFCE desktop, see `layers.xfce.*`. Each variant chains the ones
              beneath it in on its own (e.g. `xfce.develop` -> `xfce.standard` -> `xfce.base` ->
              `console.desktop` -> `server` -> `core`), so the single variant a host wants is all
              its args need. Setting more than one is harmless - layers only ever add.
            '';
            type = types.submodule {
              options = {
                base = lib.mkOption {
                  description = "Minimal XFCE desktop, see `layers.xfce.base`";
                  type = types.bool;
                  default = xfce.base or false;
                };
                standard = lib.mkOption {
                  description = "Full general purpose XFCE desktop, see `layers.xfce.standard`";
                  type = types.bool;
                  default = xfce.standard or false;
                };
                develop = lib.mkOption {
                  description = "Desktop with development tooling, see `layers.xfce.develop`";
                  type = types.bool;
                  default = xfce.develop or false;
                };
                laptop = lib.mkOption {
                  description = "Desktop with laptop tooling/configs, see `layers.xfce.laptop`";
                  type = types.bool;
                  default = xfce.laptop or false;
                };
                theater = lib.mkOption {
                  description = "Desktop tuned for a media theater, see `layers.xfce.theater`";
                  type = types.bool;
                  default = xfce.theater or false;
                };
              };
            };
            default = { };
          };

          drives = lib.mkOption {
            description = ''
              Drives this host boots from, in the order its `hardware-configuration.nix` expects
              them. Populated from `host.drives` in the host's `args.enc.yaml` - UUIDs are needed at
              evaluation time, which is exactly why they live in build-time args (see CLAUDE.md §7).
            '';
            type = types.listOf (types.submodule {
              options = {
                uuid = lib.mkOption {
                  description = "Drive identifier, as found under /dev/disk/by-uuid";
                  type = types.str;
                  default = "";
                };
              };
            });
            default = host.drives or [ ];
            example = [{ uuid = "3912bf1f-7d08-4a97-a3ee-b89fab45cdf8"; }];
          };

          resolution = lib.mkOption {
            description = "Display resolution, see `virtualization.qemu.guest.resolution`";
            type = types.submodule {
              options = {
                x = lib.mkOption {
                  description = "Horizontal resolution in pixels";
                  type = types.int;
                  default = host.resolution.x or 0;
                };
                y = lib.mkOption {
                  description = "Vertical resolution in pixels";
                  type = types.int;
                  default = host.resolution.y or 0;
                };
              };
            };
            default = { };
            example = { x = 1920; y = 1080; };
          };

          autologin = lib.mkOption {
            description = "Automatically log the primary user in after boot, see `system.x11.autologin`";
            type = types.bool;
            default = host.autologin or false;
          };

          autolock = lib.mkOption {
            description = "Automatically lock the screen when idle, see `system.x11.autolock`";
            type = types.bool;
            default = host.autolock or false;
          };

          locale = lib.mkOption {
            description = "Locale to use for various identifiers";
            type = types.str;
            default = if (host.locale or "" == "") then "en_US.UTF-8" else host.locale;
          };

          timezone = lib.mkOption {
            description = "Timezone to use for various identifiers";
            type = types.str;
            default = if (host.timezone or "" == "") then "Etc/GMT" else host.timezone;
          };

          boot = {
            efi = lib.mkOption {
              description = "Whether this machine boots via EFI";
              type = types.bool;
              default = host.boot.efi or false;
            };

            mbr = lib.mkOption {
              description = "BIOS MBR boot device, see `devices.boot.mbr`";
              type = types.str;
              default = host.boot.mbr or "nodev";
              example = "/dev/sda";
            };
          };

          network = {

            nic0 = lib.mkOption {
              description = "Primary NIC options, see `devices.network.nic0`";
              type = types.submodule (import ./types/nic.nix { inherit lib; defaults = nic0Defaults; });
              default = nic0Defaults;
            };

            gateway = lib.mkOption {
              description = "Default gateway, see `devices.network.gateway`";
              type = types.str;
              default = host.network.gateway or "";
            };

            subnet = lib.mkOption {
              description = "Default subnet/CIDR, see `devices.network.subnet`";
              type = types.str;
              default = host.network.subnet or "";
            };

            domain = lib.mkOption {
              description = ''
                Domain name owned by this host, forwarded below to every service that needs to know
                the fleet's zone name (`services.native.caddy.baseDomain`,
                `services.native.vaultwarden.baseDomain`, `services.native.adguard.baseDomain`,
                `services.oci.pangolin.baseDomain`) so the literal zone stays out of tracked files.
              '';
              type = types.str;
              default = host.network.domain or "";
            };

            dns = lib.mkOption {
              description = "DNS options, see `devices.network.dns`";
              type = types.submodule (import ./types/dns.nix { inherit lib; defaults = dnsDefaults; });
              default = dnsDefaults;
            };

            allowList = lib.mkOption {
              description = ''
                Trusted management IPs/CIDRs exempted from the hardening mechanisms: the geo-filter
                (`devices.network.harden.geoblockAllowList`), CrowdSec's ban engine
                (`services.native.crowdsec.allowlist`), and on a Pangolin host its Traefik CrowdSec
                bouncer (`services.oci.pangolin.trustedClients`) - e.g. a homelab's public IP so its
                Newt can always register.
              '';
              type = types.listOf types.str;
              default = host.network.allowList or [ ];
            };
          };

          sopsFile = lib.mkOption {
            description = ''
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

          backupDir = lib.mkOption {
            description = ''
              Parent directory this host's services snapshot their data into nightly, each under
              its own `<backupDir>/<app>` subdirectory - forwarded below to every service that
              supports it. `null` (the default) leaves backups disabled on this host.
            '';
            type = types.nullOr types.str;
            default = host.backupDir or null;
            example = "/mnt/Apps/homelab";
          };

          nix.cache.enable = lib.mkOption {
            description = ''
              Consume the fleet's Nix binary cache, see `services.native.nix-cache.client`. The
              cache host's address comes from `host.services.native.nix-cache.client.*` in args, so
              this single flag is all a client host needs.
            '';
            type = types.bool;
            default = host.nix.cache.enable or false;
          };

          nix.stateVersion = lib.mkOption {
            description = ''
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
              description = "Git user name for flake management";
              type = types.str;
              default = host.git.user or "";
            };

            email = lib.mkOption {
              description = "Git user email for flake management";
              type = types.str;
              default = host.git.email or "";
            };
          };

          users.root.authorizedKeys = lib.mkOption {
            description = "SSH authorized keys for the root user";
            type = types.listOf types.str;
            default = host.users.root.authorizedKeys or [ ];
          };

          services = lib.mkOption {
            description = ''
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
      devices.network.dns.primary = if cfg.network.dns.primary == null then "" else cfg.network.dns.primary;
      devices.network.dns.fallback = lib.mkIf (cfg.network.dns.fallback != null) cfg.network.dns.fallback;
      devices.network.nic0.name = cfg.network.nic0.name;
      devices.network.nic0.ip = cfg.network.nic0.ip;
      devices.network.nic0.mapNameFromMAC = cfg.network.nic0.mapNameFromMAC;
      devices.network.harden.geoblockAllowList = cfg.network.allowList;
      users.users.root.openssh.authorizedKeys.keys = cfg.users.root.authorizedKeys;
    }

    # Every xfce variant bottoms out in `layers.xfce.base`, so the shared host-level desktop
    # settings are forwarded there once, for whichever variant is on. The resolution is only
    # forwarded when actually set and as a `mkDefault` so a higher layer (e.g. `xfce.theater`) or
    # the host itself can still override it.
    (lib.mkIf (lib.any (x: x) (lib.attrValues cfg.desktop.xfce)) (lib.mkMerge [
      { layers.xfce.base.autologin = lib.mkIf cfg.autologin true; }
      (lib.mkIf (cfg.resolution.x != 0 && cfg.resolution.y != 0) {
        layers.xfce.base.resolution.x = lib.mkDefault cfg.resolution.x;
        layers.xfce.base.resolution.y = lib.mkDefault cfg.resolution.y;
      })
    ]))
    (lib.mkIf cfg.desktop.xfce.base { layers.xfce.base.enable = true; })
    (lib.mkIf cfg.desktop.xfce.standard { layers.xfce.standard.enable = true; })
    (lib.mkIf cfg.desktop.xfce.develop { layers.xfce.develop.enable = true; })
    (lib.mkIf cfg.desktop.xfce.laptop { layers.xfce.laptop.enable = true; })
    (lib.mkIf cfg.desktop.xfce.theater { layers.xfce.theater.enable = true; })

    (lib.mkIf config.system.x11.enable {
      system.x11.sopsFile = cfg.sopsFile;
    })

    { system.x11.autolock.enable = lib.mkIf cfg.autolock true; }

    (lib.mkIf cfg.type.vm {
      virtualization.qemu.guest.enable = true;
      virtualization.qemu.guest.hostname = cfg.name;
      virtualization.qemu.guest.sopsFile = cfg.sopsFile;
      # Only forward an explicitly set resolution; a 0x0 default would otherwise clobber
      # virtualization.qemu.guest.resolution's own 1920x1080 default.
      virtualization.qemu.guest.resolution = lib.mkIf (cfg.resolution.x != 0 && cfg.resolution.y != 0)
        { inherit (cfg.resolution) x y; };
      virtualization.qemu.guest.bridge = config.devices.network.bridge.name;

      # Virtual disks expose no S.M.A.R.T. data so smartd would fail to start having found no
      # devices to monitor. Forced so it wins over any layer that turns it on for physical hosts.
      services.native.smartd.enable = lib.mkForce false;
    })

    (lib.mkIf config.virtualization.qemu.host.enable {
      virtualization.qemu.host.sopsFile = cfg.sopsFile;
      virtualization.qemu.host.bridge = config.devices.network.bridge.name;
    })

    (lib.mkIf cfg.nix.cache.enable {
      services.native.nix-cache.client.enable = true;
    })

    (lib.mkIf config.services.native.nix-cache.client.enable (
      let arg = f.getSvcFunc "native.nix-cache" cfg.services;
      in {
        services.native.nix-cache.client.hostIP = arg "client.hostIP";
        services.native.nix-cache.client.hostPort = arg "client.hostPort";
      }
    ))

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
        services.native.caddy.trustedProxies = arg "trustedProxies";
      }
    ))

    # Each Newt instance reaches Caddy from its fixed container IP (see
    # modules/services/oci/newt.nix), so trust the X-Forwarded-For it carries from Pangolin's
    # Traefik. Enabled instances only. Merges with any args-supplied list.
    (lib.mkIf (config.services.native.caddy.enable && config.services.oci.newt.enable) {
      services.native.caddy.trustedProxies = lib.mapAttrsToList (_: inst: "${inst.ip}/32")
        (lib.filterAttrs (_: inst: inst.enable && inst.ip != null) config.services.oci.newt.instances);
    })

    (lib.mkIf config.services.native.vaultwarden.enable {
      services.native.vaultwarden.sopsFile = cfg.sopsFile;
      services.native.vaultwarden.baseDomain = cfg.network.domain;
    })

    (lib.mkIf config.services.native.adguardhome.enable (
      let arg = f.getSvcFunc "native.adguardhome" cfg.services;
      in {
        services.native.adguardhome.sopsFile = cfg.sopsFile;
        services.native.adguardhome.baseDomain = cfg.network.domain;
        services.native.adguardhome.bindAddress = (f.toIP config.devices.network.primary.ip).address;
        services.native.adguardhome.dnsRewrites = arg "dnsRewrites";
      }
    ))

    (lib.mkIf config.services.native.mullvad.enable {
      services.native.mullvad.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf config.apps.dev.claude.enable {
      apps.dev.claude.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf config.services.native.alerts.enable {
      services.native.alerts.sopsFile = cfg.sopsFile;
    })

    (lib.mkIf config.services.native.crowdsec.enable {
      services.native.crowdsec.sopsFile = cfg.sopsFile;
      services.native.crowdsec.allowlist = cfg.network.allowList;
    })

    # Nightly backups, each service snapshots into its own `<backupDir>/<app>` subdirectory
    (lib.mkIf (cfg.backupDir != null) {
      services.native.adguardhome.backupDir = lib.mkIf config.services.native.adguardhome.enable cfg.backupDir;
      services.native.jellyfin.backupDir = lib.mkIf config.services.native.jellyfin.enable cfg.backupDir;
      services.native.vaultwarden.backupDir = lib.mkIf config.services.native.vaultwarden.enable cfg.backupDir;
      services.oci.homarr.backupDir = lib.mkIf config.services.oci.homarr.enable cfg.backupDir;
      services.oci.oneup.backupDir = lib.mkIf config.services.oci.oneup.enable cfg.backupDir;
    })

    # Shared OCI service forwarding, see `ociForward` above. Pangolin and Portainer are not in this
    # list: neither is built on modules/types/service.nix, so they have no common field set to
    # forward (Pangolin has its own block below).
    (lib.mkIf config.services.oci.homarr.enable { services.oci.homarr = ociForward "homarr"; })
    (lib.mkIf config.services.oci.immich.enable (lib.mkMerge [
      { services.oci.immich = ociForward "immich"; }
      { services.oci.immich.bridge = config.devices.network.bridge.name; }
    ]))
    (lib.mkIf config.services.oci.oneup.enable { services.oci.oneup = ociForward "oneup"; })
    (lib.mkIf config.services.oci.stirling-pdf.enable { services.oci.stirling-pdf = ociForward "stirling-pdf"; })

    (lib.mkIf config.services.oci.pangolin.enable (
      let arg = f.getSvcFunc "oci.pangolin" cfg.services;
      in {
        services.oci.pangolin.sopsFile = cfg.sopsFile;
        services.oci.pangolin.baseDomain = cfg.network.domain;
        services.oci.pangolin.acmeEmail = arg "acmeEmail";
        services.oci.pangolin.trustedClients = cfg.network.allowList;
      }
    ))

    (lib.mkIf config.services.oci.newt.enable (
      let arg = f.getSvcFunc "oci.newt" cfg.services;
      in {
        # Not `ociForward`: Newt has no shared subnet/ip/caddy/subdomain - each instance has its
        # own subnet/ip, and its whole connection (`pangolin.url`/`ip`, `id`, `subnet`, `ip`) comes
        # from `host.services.oci.newt.instances.<instance>.*`. Every instance defined there is
        # enabled by default.
        services.oci.newt = {
          sopsFile = cfg.sopsFile;
          name = arg "name";
          tag = arg "tag";
          user = arg "user";
          port = arg "port";
          instances = arg "instances";
        };
      }
    ))
  ];
}
