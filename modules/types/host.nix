# Declares a host type: used for module orchestration
#
# ### Features
# - args is the composed/overridden set of user arguments for this host
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
  # Validation is done directly
  #imports = [ ./validate_host.nix ];

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
              type = types.submodule (import ./nic.nix { inherit lib; defaults = nic0Defaults; });
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
              description = lib.mdDoc "Domain name owned by this host, e.g. for use with Caddy/Cloudflare DNS-01";
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
              Path to this machine's sops-encrypted secrets file. Not sourced from `args` (same
              reasoning as `host.secrets`: secrets stay sops-encrypted on disk and can't flow
              through the `args` merge like plain data) - resolved from `hosts/<hostname>/secrets.enc.yaml`
              if it exists.
            '';
            type = types.nullOr types.path;
            default =
              let file = ../hosts + "/${cfg.name}/secrets.enc.yaml";
              in if cfg.name != "" && builtins.pathExists file then file else null;
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
      services.native.crowdsec.sopsFile = cfg.sopsFile;
      services.native.alerts.sopsFile = cfg.sopsFile;
      services.native.crowdsec.allowlist = cfg.network.allowList;
      users.users.root.openssh.authorizedKeys.keys = cfg.users.root.authorizedKeys;

      services.native.smb.enable = lib.mkIf (f.getServiceAttr "native.smb.enable" cfg.services == true) true;
      services.native.nfs.enable = lib.mkIf (f.getServiceAttr "native.nfs.enable" cfg.services == true) true;

      apps.games.prismlauncher.hostname = cfg.name;
    }

    (lib.mkIf cfg.desktop.xfce {
      layers.xfce = {
        desktop.enable = true;
        base.autologin = cfg.autologin;
        base.resolution = { inherit (cfg.resolution) x y; };
      };
    })

    # Configure the system to be a virtual machine
    (lib.mkIf cfg.type.vm {
      virtualization.qemu.guest.enable = true;
      virtualization.qemu.guest.hostname = cfg.name;
      virtualization.qemu.guest.resolution = { inherit (cfg.resolution) x y; };
      virtualization.qemu.guest.bridge = config.devices.network.bridge.name;
    })

    # Configure smb shares from this host's build-time args and runtime secrets
    (lib.mkIf config.services.native.smb.enable (
      let
        arg = name: f.getServiceAttr "native.smb.${name}" cfg.services;
        fromArgs = name: lib.mkIf (arg name != null) (arg name);
      in {
        services.native.smb = {
          sopsFile = cfg.sopsFile;
          user = fromArgs "user";
          pass = fromArgs "pass";
          domain = fromArgs "domain";
          dirMode = fromArgs "dirMode";
          fileMode = fromArgs "fileMode";
          entries = fromArgs "entries";
        };
      }
    ))

    # Configure nfs shares from this host's build-time args
    (lib.mkIf config.services.native.nfs.enable (
      let
        arg = name: f.getServiceAttr "native.nfs.${name}" cfg.services;
        fromArgs = name: lib.mkIf (arg name != null) (arg name);
      in {
        services.native.nfs = {
          fsType = fromArgs "fsType";
          options = fromArgs "options";
          entries = fromArgs "entries";
        };
      }
    ))

    # Configure pangolin from shared defaults and secrets
    (lib.mkIf config.services.oci.pangolin.enable {
      services.oci.pangolin.sopsFile = cfg.sopsFile;
      services.oci.pangolin.baseDomain = cfg.network.domain;
      services.oci.pangolin.acmeEmail = f.getServiceAttr "oci.pangolin.acmeEmail" cfg.services;
      services.oci.pangolin.geoblockAllowList = cfg.network.allowList;
    })
  ];
}


# { lib, args, f, ... }: with lib.types;
# let
#   smb = import ./smb.nix { inherit lib; };
#
#   # Defaults to use for uniformity across the different default use cases
#   defaults = {
#     user = let
#       u    = args.user or {};
#       name = u.name or "admin";
#     in {
#       name     = name;
#       pass     = u.pass     or "admin";
#       fullname = u.fullname or name;
#       email    = u.email    or "";
#       # Hardcoded to match modules/system/users.nix's own literal `uid = 1000;` for the admin
#       # account, rather than reading back from `config.users.users.${name}` - that lazily forces
#       # NixOS to materialize a `users.users.<name>` submodule instance merely by being referenced,
#       # which breaks on non-ISO hosts (the account is created imperatively via secret.users, no
#       # such declarative instance exists to read).
#       uid      = 1000;
#       gid      = 1000;
#     };
#     macvlan = (f.getNic args "macvlan");
#     nic0 = (f.getNic args "nic0");
#     nic1 = (f.getNic args "nic1");
#   };
# in
# {
#   imports = [
#     ./validate_host.nix
#   ];
#
#   options = {
#     host = lib.mkOption {
#       description = lib.mdDoc "Host configuration definition";
#       type = types.submodule {
#         options = {
#           type = lib.mkOption {
#             description = lib.mdDoc ''
#               Host types are descriptive capabilities of a host. These types are not mutually 
#               exclusive. For instance a host might be both an ISO and also a development host. At 
#               least one type must be specified though.
#             '';
#             type = types.submodule {
#               options = {
#                 vm = lib.mkEnableOption "Host is a virtual and does not need a bootloader";
#                 iso = lib.mkEnableOption "Host is intended to be used as an ISO image";
#                 develop = lib.mkEnableOption "Host is intended to be used as a Development system";
#                 theater = lib.mkEnableOption "Host is intended to be used as a Theater system";
#               };
#             };
#             default = {
#               # Note: not defining the other defaults here as I don't expect to support them in args
#               iso = args.host.type.iso or false;
#             };
#           };
#
#           target = lib.mkOption {
#             description = lib.mdDoc "Host or layer used during installation";
#             type = types.str;
#             default = args.host.target or "";
#           };
#
#           drives = lib.mkOption {
#             description = lib.mdDoc "Drive options";
#             type = types.listOf (types.submodule {
#               options = {
#                 uuid = lib.mkOption {
#                   description = lib.mdDoc "Drive identifier";
#                   type = types.str;
#                   default = "";
#                 };
#               };
#             });
#             default = args.host.drives or [];
#           };
#
#           arch = lib.mkOption {
#             description = lib.mdDoc "System architecture";
#             type = types.str;
#             default = if (args.host.arch or "" == "") then "x86_64-linux" else args.host.arch;
#           };
#
#           autologin = lib.mkOption {
#             description = lib.mdDoc "Enable autologin";
#             type = types.bool;
#             default = args.host.autologin or false;
#           };
#
#           bluetooth = lib.mkOption {
#             description = lib.mdDoc "Enable bluetooth";
#             type = types.bool;
#             default = args.host.bluetooth or false;
#           };
#
#           resolution = lib.mkOption {
#             description = lib.mdDoc "Display resolution";
#             type = types.attrs;
#             default = {
#               x = args.host.resolution.x or 0;
#               y = args.host.resolution.y or 0;
#             };
#           };
#
#           nix = lib.mkOption {
#             type = types.submodule {
#               options = {
#                 minVer = lib.mkOption {
#                   description = lib.mdDoc "Minimal support Nixpkgs version";
#                   type = types.str;
#                   default = if (args.host.nix.minVer or "" == "") then "25.05" else args.host.nix.minVer;
#                 };
#                 cache = lib.mkOption {
#                   description = lib.mdDoc "Nix Binary cache configuration";
#                   type = types.submodule {
#                     options = {
#                       enable = lib.mkOption {
#                         description = lib.mdDoc "Enable using a custom Nix binary cache";
#                         type = types.bool;
#                         default = args.host.nix.cache.enable or false;
#                       };
#                       ip = lib.mkOption {
#                         description = lib.mdDoc "IP address of the custom Nix binary cache";
#                         type = types.str;
#                         default = args.host.nix.cache.ip or "";
#                       };
#                       port = lib.mkOption {
#                         description = lib.mdDoc "Port of the custom Nix binary cache";
#                         type = types.int;
#                         default = args.host.nix.cache.port or 5000;
#                       };
#                     };
#                   };
#                   default = {
#                     enable = args.host.nix.cache.enable or false;
#                     ip = args.host.nix.cache.ip or "";
#                     port = args.host.nix.cache.port or 5000;
#                   };
#                 };
#               };
#             };
#             default = {
#               minVer = if (args.host.nix.minVer or "" == "") then "25.05" else args.host.nix.minVer;
#               cache = {
#                 enable = args.host.nix.cache.enable or false;
#                 ip = args.host.nix.cache.ip or "";
#                 port = args.host.nix.cache.port or 5000;
#               };
#             };
#           };
#
#           git = lib.mkOption {
#             type = types.submodule {
#               options = {
#                 user = lib.mkOption {
#                   description = lib.mdDoc "Git user name";
#                   type = types.str;
#                   default = args.host.git.user or "";
#                 };
#                 email = lib.mkOption {
#                   description = lib.mdDoc "Git email address";
#                   type = types.str;
#                   default = args.host.git.email or "";
#                 };
#                 comment = lib.mkOption {
#                   description = lib.mdDoc "System build comment";
#                   type = types.str;
#                   default = args.host.git.comment or "";
#                 };
#               };
#             };
#             default = {
#               user = args.host.git.user or "";
#               email = args.host.git.email or "";
#               comment = args.host.git.comment or "";
#             };
#           };
#
#           # Networking options for the whole host
#           # ----------------------------------------------------------------------------------------------
#           net = lib.mkOption {
#             description = lib.mdDoc "Networking options for the host";
#             type = types.submodule {
#               options = {
#                 gateway = lib.mkOption {
#                   description = lib.mdDoc "Default gateway to use for host";
#                   type = types.str;
#                   example = "192.168.1.1";
#                   default = args.net.gateway or "";
#                 };
#                 subnet = lib.mkOption {
#                   description = lib.mdDoc "Default subnet to use for host";
#                   type = types.str;
#                   example = "192.168.1.0/24";
#                   default = args.net.subnet or "";
#                 };
#                 dns = lib.mkOption {
#                   description = lib.mdDoc "Default dns to use for host";
#                   type = types.submodule (import ./dns.nix { inherit lib; defaults = args.net.dns or 
#                       { primary = ""; fallback = ""; }; });
#                   default = args.net.dns or { primary = ""; fallback = ""; };
#                 };
#                 bridge = {
#                   enable = lib.mkEnableOption ''
#                     Convert the main interface into a bridge which then allows virtualized devices like 
#                     containers and VMs to join the LAN, be assigend LAN IP addresses and fully interact 
#                     with other devices on the LAN. All of the other primary network settings will be used 
#                     for the new bridge interface.
#
#                     Note, for bridge mode to work the primary nic must be specified via "net.nic0.name".
#                     This can be done via the "args.enc.yaml" or directly in the "configuration.nix" file.
#
#                     1. configuration.nix example
#                     host.net.nic0.name = "eth0";
#
#                     2. args.enc.yaml example
#                     {
#                       "net": {
#                         "nic0": {
#                           "name": "enp1s0",
#                         }
#                       }
#                     }
#                   '';
#                   name = lib.mkOption {
#                     type = types.str;
#                     description = lib.mdDoc "Name to use for the new bridge";
#                     default = "br0";
#                   };
#                 };
#                 macvlan = lib.mkOption {
#                   description = lib.mdDoc ''
#                     Create a macvlan interface for the host to use on the bridge, which allows the host to 
#                     communicate with virtualized devices connected to the bridge. Otherwise the virtualized 
#                     devices can fully participate on the LAN but the host won't be able to interact directly 
#                     with the virtualized devices.
#                   '';
#                   type = types.submodule (import ./nic.nix { inherit lib; defaults = defaults.macvlan; });
#                   default = defaults.macvlan;
#                 };
#                 nic0 = lib.mkOption {
#                   description = lib.mdDoc "Primary NIC options";
#                   type = types.submodule (import ./nic.nix { inherit lib; defaults = defaults.nic0; });
#                   default = defaults.nic0;
#                 };
#                 nic1 = lib.mkOption {
#                   description = lib.mdDoc "Secondary NIC options";
#                   type = types.submodule (import ./nic.nix { inherit lib; defaults = defaults.nic1; });
#                   default = defaults.nic1;
#                 };
#               };
#             };
#             default = {
#               gateway = args.net.gateway or "";
#               subnet = args.net.subnet or "";
#               dns = args.net.dns or { primary = ""; fallback = ""; };
#               bridge = { enable = false; };
#               macvlan = defaults.macvlan;
#               nic0 = defaults.nic0;
#               nic1 = defaults.nic1;
#             };
#           };
#
#           nfs = lib.mkOption {
#             type = types.submodule {
#               options = {
#                 enable = lib.mkOption {
#                   description = lib.mdDoc "Enable NFS shares";
#                   type = types.bool;
#                   default = args.nfs.enable or false;
#                 };
#                 entries = lib.mkOption {
#                   description = lib.mdDoc "Share entries to configure";
#                   type = types.listOf (types.submodule {
#                     options = {
#                       mountPoint = lib.mkOption {
#                         description = lib.mdDoc "Share mount point";
#                         type = types.str;
#                         example = "/mnt/Media";
#                       };
#                       remotePath = lib.mkOption {
#                         description = lib.mdDoc "Remote path to use for the share";
#                         type = types.str;
#                         example = "192.168.1.2:/srv/nfs/Media";
#                       };
#                       fsType = lib.mkOption {
#                         description = lib.mdDoc "Share file system type";
#                         type = types.str;
#                         example = "nfs";
#                       };
#                       options = lib.mkOption {
#                         description = lib.mdDoc "Share options";
#                         type = types.listOf types.str;
#                         example = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
#                       };
#                     };
#                   });
#                   default = args.nfs.entries or [];
#                 };
#               };
#             };
#             default = {
#               enable = args.nfs.enable or false;
#               entries = args.nfs.entries or [];
#             };
#           };
#
#           smb = lib.mkOption {
#             type = types.submodule smb;
#             default = {
#               enable = args.smb.enable or false;
#               user = args.smb.user or defaults.user.name;
#               pass = args.smb.pass or defaults.user.pass;
#               domain = args.smb.domain or "";
#               dirMode = args.smb.dirMode or "0755";
#               fileMode = args.smb.fileMode or "0644";
#               entries = if (args ? "smb" && args.smb ? "entries") then (builtins.concatMap (x: [{
#                 mountPoint = x.mountPoint or "";
#                 remotePath = x.remotePath or "";
#                 user = x.user or (args.smb.user or defaults.user.name);
#                 pass = x.pass or (args.smb.pass or defaults.user.pass);
#                 domain = if (x ? "domain" && x.domain != "") then x.domain else args.smb.domain or "";
#                 dirMode = if (x ? "dirMode" && x.dirMode != "") then x.dirMode else args.smb.dirMode or "0755";
#                 fileMode = if (x ? "fileMode" && x.fileMode != "") then x.fileMode else args.smb.fileMode or "0644";
#                 writable = x.writable or false;
#                 options = x.options or [];
#               }]) args.smb.entries) else [];
#             };
#           };
#
#           user = lib.mkOption {
#             description = lib.mdDoc "User options";
#             type = types.submodule (import ./user.nix { inherit lib; defaults = defaults.user; });
#             default = defaults.user;
#           };
#
#           secrets = lib.mkOption {
#             description = lib.mdDoc ''
#               Path to this host's sops-encrypted secrets, holding real secrets that must never be
#               baked into the Nix store (the admin user's password/password hash, Samba passwords,
#               service encryption keys, etc). Declared once here so every module that needs one of
#               this host's secrets (`modules/users.nix`, `modules/services/raw/smb`, ...) can
#               reference `config.host.secrets` instead of repeating a `secrets = ./secrets.enc.yaml;`
#               option per module the way the independent per-service secrets (newt/caddy/tailscale) do.
#
#               Layering (lowest to highest priority): `secrets.enc.yaml` -> `hosts/<hostname>/secrets.enc.yaml`.
#               Unlike args, secrets stay sops-encrypted until sops-nix decrypts them at activation
#               time on the target host, so the two layers can't be merged with `recursiveUpdate` at
#               Nix eval time the way args are - instead `clu` (`lib/flake`'s `flake::decrypt_secrets`,
#               run alongside `flake::decrypt_args`) decrypts both, merges them (host wins on
#               conflicting keys), and re-encrypts the result into a transient
#               `hosts/<hostname>/secrets.merged.enc.yaml`, which this default resolves to whenever a
#               host override exists. That file is staged just long enough to build and dropped
#               afterward (`flake::restore_secrets`), exactly like `args.dec.yaml`.
#
#               A `hosts/<hostname>/.isolated` marker (see `hosts/vps`) opts a host out of this
#               layering entirely, just like it does for args - it must be fully self-contained in its
#               own `secrets.enc.yaml`, never merged with the fleet's shared root secrets.
#             '';
#             type = types.nullOr types.path;
#             example = "./secrets.enc.yaml";
#             default =
#               let
#                 hostname = args.host.name or "";
#                 isolated = builtins.pathExists (../../hosts + "/${hostname}/.isolated");
#                 ownFile = ../../hosts + "/${hostname}/secrets.enc.yaml";
#                 mergedFile = ../../hosts + "/${hostname}/secrets.merged.enc.yaml";
#                 rootFile = ../../secrets.enc.yaml;
#                 hasOwn = builtins.pathExists ownFile;
#               in
#                 if isolated then (if hasOwn then ownFile else null)
#                 else if hasOwn then mergedFile
#                 else if builtins.pathExists rootFile then rootFile
#                 else null;
#           };
#
#           services = lib.mkOption {
#             description = lib.mdDoc ''
#               Per-service values sourced from args, keyed by service name, for details (like a remote
#               server's LAN IP) that should stay out of tracked files rather than being hardcoded in a
#               host's configuration.nix.
#             '';
#             type = types.submodule {
#               options = {
#                 raw = lib.mkOption {
#                   description = lib.mdDoc ''
#                     Values for `services.raw.*` modules, e.g. `host.services.raw.adguard.host` for a
#                     remote AdGuard instance's LAN IP fronted by `services.raw.caddy`. Populated from
#                     `args.services.raw.<name>.host` in `args.enc.yaml`/`args.nix`.
#                   '';
#                   type = types.attrsOf (types.submodule {
#                     options = {
#                       host = lib.mkOption {
#                         description = lib.mdDoc "LAN IP or hostname of the target service";
#                         type = types.str;
#                         default = "";
#                       };
#                     };
#                   });
#                   default = args.services.raw or {};
#                 };
#               };
#             };
#             default = {
#               raw = args.services.raw or {};
#             };
#           };
#         };
#       };
#     };
#   };
# }
