# MacBook configuration
#
# ### Features
# - MacBook laptop deployment
# --------------------------------------------------------------------------------------------------
{ inputs, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/develop.nix

    # t2 modules from nixos hardware are pinned in the flake
    inputs.nixos-hardware.nixosModules.apple-t2
  ];

  config = {
    machine.type.bootable = true;
    apps.system.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    # Increase the default DPI size
    machine.resolution = { x = 1920; y = 1200; } ;
    system.x11.xft.dpi = lib.mkForce 120;

    # Fix default power governor to run at a lower frequency and boost as needed
    powerManagement.cpuFreqGovernor = "schedutil";

    # Blacklist open source broadcom drivers
    boot.blacklistedKernelModules = [ "b43" "bcma" ];

    # Apple firmware configuration
    nix.settings = {
      trusted-substituters = [ "https://t2linux.cachix.org" ];
      trusted-public-keys = [ "t2linux.cachix.org-1:P733c5Gt1qTcxsm+Bae0renWnT8OLs0u9+yfaK2Bejw=" ];
    };
    hardware.firmware = [
      (pkgs.stdenvNoCC.mkDerivation (final: {
        name = "brcm-firmware";
        src = /lib/firmware/brcm;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          cp ${final.src}/* "$out/lib/firmware/brcm"
        '';
      }))
    ];

    apps.dev.claude.enable = true;
    apps.media.obs.enable = true;
    apps.network.rustdesk.autostart = false;

    environment.systemPackages = [
      pkgs.python3
      pkgs.dmg2img
      (pkgs.callPackage ../../modules/hardware/apple.nix {})
    ];

    # Built-in ethernet gets a worse route metric than wifi (600) so that whenever both are up
    # (e.g. dock left plugged in while tethered to a phone hotspot), wifi always wins the default
    # route/DNS instead of a dead or lower-priority ethernet link. Ethernet still works fine as the
    # primary connection when it's the only one active.
    networking.networkmanager.ensureProfiles.profiles."Wired connection 1" = {
      connection = {
        id = "Wired connection 1";
        type = "ethernet";
        interface-name = "enp2s0f1u1";
        autoconnect-priority = -999;
      };
      ipv4 = {
        method = "auto";
        route-metric = 700;
      };
      ipv6 = {
        method = "auto";
        addr-gen-mode = "default";
        route-metric = 700;
      };
    };
  };
}
