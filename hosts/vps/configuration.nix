# vps configuration
#
# ### Features
# - Virtual Machine deployment
# - Isolated from shared fleet config/secrets (see hosts/vps/.isolated) - args and secrets are
#   entirely self-contained under this directory, encrypted with a dedicated sops age key
#   (see .sops.yaml), not the fleet's shared args.nix/args.enc.json/secrets.enc.yaml
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../modules/virtualisation/qemu/guest.nix
    ../../layers/bundles/xfce-desktop.nix
    #../../layers/bundles/budgie-desktop.nix
  ];

  config = {
    host.type.vm = true;
    host.vm.type.local = true;
    host.resolution = { x = 1920; y = 1080; };
    host.autologin = true;
    host.secrets = ./secrets.enc.yaml;   # own secrets only - never the shared fleet default

    # vps is a static VM behind QEMU's NAT, not a roaming machine, so there's no captive
    # portal to support - force every query through the upstream DNS set in args.enc.json instead
    # of letting NetworkManager's DHCP-provided per-link DNS (QEMU's slirp forwarder) win.
    host.net.dns.force = true;

    apps.dev.claude.enable = true;

    # Beefed up VM specs with DHCP full LAN presence
    # --------------------------------------------
    virtualisation.qemu.guest = {
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      display.enable = true;
      interfaces = [{
        type = "user";
        id = "vps";
        forwardPorts = [
          { host = 8080; guest = 80; }
          { host = 8443; guest = 443; }
          { host = 9000; guest = 9000; }
        ];
      }];
    };
  };
}
