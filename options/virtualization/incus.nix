# Incus configuration
#
# ### Features
# - purposefully renaming `virtualization` to give me a new namespace to work in
# - makes use of the `incus admin init --preseed` to configure incus programmatically
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.incus;
  static_ip = f.toIP "${args.static_ip}";
in
{
  options = {
    virtualization.incus = {
      enable = lib.mkEnableOption "Install and configure Incus";

      port = lib.mkOption {
        description = lib.mdDoc "API port";
        type = types.port;
        default = 8443;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Ensure we are using a bridge networking device to allow the possibility of having VMs show up 
    # on the network without too much trouble.
    networking.bridge.enable = true;

    # Configure primary user permissions
    users.users.${args.username}.extraGroups = [ "incus-admin" ];

    # Setup firewall exceptions:
    # https://wiki.nixos.org/wiki/Incus
    # - allow DHCP and DNS to the incus networks
    networking.firewall.interfaces.${config.networking.vnic0}.allowedTCPPorts = [ cfg.port ];
    networking.firewall.interfaces."incusbr0".allowedTCPPorts = [ 53 67 ];

    # Enable and configure the app
    virtualisation.incus = {
      enable = true;
      preseed = {
        config = [{
          core = {
            https_address = "${static_ip.address}:${toString cfg.port}";
          };
          # images.auto_update_interval = 15;
        }];
        networks = [{
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "auto";
            "ipv6.address" = "none";
            "ipv4.nat" = "true";
          };
        }];
        storage_pools = [{
          name = "default";
          driver = "dir";
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
        }];
        profiles = [{
          name = "default";
#          config = {
#            "security.nesting" = true;
#            "security.privileged" = true;
#          };
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              pool = "default";
              path = "/";
              type = "disk";
            };
            nix_store = {
              type = "disk";
              path = "/nix/store";
              readonly = true;
              source = "path";
            };
          };
        }];
      };
    };
  };
}
