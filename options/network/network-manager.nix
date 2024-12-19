# Network manager configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.network.network-manager;

in
{
  options = {
    network.network-manager = {
      enable = lib.mkEnableOption "Install and configure network manager";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Enables ability for user to make network manager changes
      users.users.${args.username}.extraGroups = [ "networkmanager" ];

      # Enable networkmanager and nm-applet by default
      networking.networkmanager = {
        enable = true;
        dns = "systemd-resolved";           # Configure systemd-resolved as the DNS provider
        unmanaged = [                       # Ignore virtualization networks
          "interface-name:podman*"
          "interface-name:vboxnet*"
          "interface-name:vmnet*"
        ];
      };
    }
  ]);
}
