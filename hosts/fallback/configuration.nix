# Fallback configuration
#
# ### Hardware
# - HP Z620 Workstation
# - (2) 4-core Intel Xeon E5-2637 v2 3.5GHz
# - Broadcom 802.11ac WiFi BCM4364 rev 3
# - Nvidia GTX 650 Ti
# - 1TB Samsung 850 Pro SSD
#
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.boot.mbr = "/dev/sdb";
    host.nix.cache.enable = true;
    host.desktop.xfce.develop = true;
    devices.gpu.nvidia = { enable = true; legacy470 = true; };

    apps.games.warcraft2.enable = true;

    environment.systemPackages = [
      #
    ];
  };
}
