# Incus configuration
#
# ### Features
# - purposefully renaming `virtualization` to give me a new namespace to work in
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.incus;
in
{
  options = {
    virtualization.incus = {
      enable = lib.mkEnableOption "Install and configure Incus";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Configure primary user permissions
    users.users.${args.username}.extraGroups = [ "incus-admin" ];

    # Enable and configure the app
    virtualisation.incus = {
      enable = true;
      preseed = {
        networks = [{
          config = {
            "ipv4.address" = "auto";
            "ipv6.address" = "none";
            "ipv4.nat" = "true";
          };
          name = "incusbr0";
          type = "bridge";
        }];
        profiles = [{
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
          name = "default";
        }];
        storage_pools = [{
          config = {
            source = "/var/lib/incus/storage-pools/default";
          };
          driver = "dir";
          name = "default";
        }];
      };
    };
  };
}
