# Declares a machine type: used for module orchestration
#
# ### Features
# - `args.machine.*` is the composed/overridden set of user arguments for this option, same
#   mechanism `host.nix` uses via the `args` specialArg, but under its own namespace so it never
#   collides with anything `host.nix` reads from `args.host.*`.
# - Inert everywhere by default: every host gets this module for free, but nothing happens unless
#   a host sets `machine.id` - that's the opt-in signal (every real machine has one; an unset host
#   just never defines `args.machine.id`).
#---------------------------------------------------------------------------------------------------
{ config, lib, args, ... }: with lib.types;
let
  cfg = config.machine;
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
  };
in
{
  # Read in all modules in all directories to make all modules options available for opt in.
  imports = [
    ./apps
    ./devices
    ../layers
    ./services
    ./system
    ./types
    ./virtualisation
  ];

  options = {
    machine = lib.mkOption {
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

          network = {
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

            networkd.enable = lib.mkOption {
              description = lib.mdDoc "Use systemd-networkd, see `devices.network.networkd.enable`";
              type = types.bool;
              default = host.network.networkd.enable or false;
            };

            nic0 = lib.mkOption {
              description = lib.mdDoc "Primary NIC options, see `devices.network.nic0`";
              type = types.submodule (import ./types/nic.nix { inherit lib; defaults = nic0Defaults; });
              default = nic0Defaults;
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

          users.root.authorizedKeys = lib.mkOption {
            description = lib.mdDoc "SSH authorized keys for the root user";
            type = types.listOf types.str;
            default = host.users.root.authorizedKeys or [ ];
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
  config = lib.mkIf (cfg.id != "") {
    devices.boot.efi = cfg.boot.efi;
    devices.boot.mbr = cfg.boot.mbr;
    networking.hostName = cfg.name;
    system.env.machineId = cfg.id;
    system.env.git.user = cfg.git.user;
    system.env.git.email = cfg.git.email;
    system.users.sopsFile = cfg.sopsFile;
    devices.network.gateway = cfg.network.gateway;
    devices.network.subnet = cfg.network.subnet;
    devices.network.nic0.name = cfg.network.nic0.name;
    devices.network.nic0.ip = cfg.network.nic0.ip;
    devices.network.dns.primary = cfg.network.dns.primary;
    devices.network.dns.fallback = cfg.network.dns.fallback;
    devices.network.networkd.enable = cfg.network.networkd.enable;
    users.users.root.openssh.authorizedKeys.keys = cfg.users.root.authorizedKeys;
  };
}
