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
{ config, pkgs, lib, args, f, ... }: with lib.types;
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/develop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    apps.games.warcraft2.enable = true;
    devices.gpu.nvidiaLegacy470 = true;

    environment.systemPackages = [
      #
    ];
  };
}
