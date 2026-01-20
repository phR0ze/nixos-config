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
    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    apps.media.obs.enable = true;
    services.raw.tailscale.enable = true;
    services.raw.rustdesk.autostart = false;

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

    environment.systemPackages = [
      pkgs.python3
      pkgs.dmg2img
      (pkgs.callPackage ../../modules/hardware/apple.nix {})
    ];
  };
}
