# Workstation configuration
#
# ### Hardware
# - HP Z620 Workstation
# - (2) 4-core Intel Xeon E5-2637 v2 3.5GHz
# - Broadcom 802.11ac WiFi BCM4364 rev 3
# - AMD Radeon RX 550
# - 1TB Samsung 850 Pro SSD
# - (2) 3 TB Seagate HDD
#
# ### Features
# - Daily driver desktop deployment
# - Barrier server configuration
# 
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/develop.nix
  ];

  config = {
    machine.type.bootable = true;
    hardware.gpu.amd = true;
    machine.net.bridge.enable = true;

    hardware.printers.epson-wf7710 = true;
    hardware.printers.brother-hll2405w = true;

    services.raw.barriers.enable = true;
    services.raw.rustdesk.autostart = false;

    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
    apps.media.freecad.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.vdhcoapp                 # Companion app for the Video DownloadHelper browser add-on
      pkgs.xchm                     # App for reading Microsoft help files for technical manuals
      pkgs.synology-drive-client
      pkgs.freetube
      #pkgs.wiiload                 # Depends on freeimage which has bit rotted
      #pkgs.wiimms-iso-tools        # Depends on freeimage which has bit rotted
      #pkgs.gamecube-tools          # Depends on freeimage which has bit rotted
      pkgs.quickemu
      pkgs.zed-editor
      pkgs.rust-analyzer
      pkgs.neovide
    ];
  };
}
