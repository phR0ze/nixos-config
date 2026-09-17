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

            nic0 = {
              name = lib.mkOption {
                description = lib.mdDoc "Primary NIC name, see `devices.network.nic0.name`";
                type = types.str;
                default = host.network.nic0.name or "";
              };

              ip = lib.mkOption {
                description = lib.mdDoc "Primary NIC IP and CIDR combination, see `devices.network.nic0.ip`";
                type = types.str;
                default = host.network.nic0.ip or "";
              };
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
    networking.hostName = cfg.name;
    system.env.machineId = cfg.id;
    system.env.git.user = cfg.git.user;
    system.env.git.email = cfg.git.email;
    system.users.sopsFile = cfg.sopsFile;
    devices.network.nic0.name = cfg.network.nic0.name;
    devices.network.nic0.ip = cfg.network.nic0.ip;
    devices.network.dns.primary = cfg.network.dns.primary;
    devices.network.dns.fallback = cfg.network.dns.fallback;
    users.users.root.openssh.authorizedKeys.keys = cfg.users.root.authorizedKeys;
  };
}
