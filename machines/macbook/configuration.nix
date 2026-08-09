# MacBook configuration
#
# ### Features
# - MacBook laptop deployment
# --------------------------------------------------------------------------------------------------
{ inputs, pkgs, lib, ... }:
let
  # dGPU power savings vs HDMI/USB-C video toggle - mutually exclusive modes, boot-only (not
  # hot-toggleable). See README.md "dGPU power saving vs HDMI/USB-C video" for full details.
  dgpuPowerSave = true;
in
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

    # The T2 chip's internal iBridge controller exposes a USB CDC-NCM "Ethernet" gadget
    # (enp2s0f1u1) with carrier permanently on but no real link behind it. NetworkManager
    # endlessly retries DHCP on it, which keeps nm-applet's tray icon spinning even though
    # the real (WiFi) connection is fine. Leave it unmanaged so NM stops trying to activate it.
    networking.networkmanager.unmanaged = [ "interface-name:enp2s0f1u1" ];

    boot.extraModprobeConfig = lib.mkIf dgpuPowerSave ''
      options apple_gmux force_igd=y
    '';
    boot.kernelParams = lib.mkIf dgpuPowerSave [ "i915.enable_guc=3" ];
    systemd.services.amdgpu-off = lib.mkIf dgpuPowerSave {
      description = "Power off the discrete AMD GPU via vga_switcheroo";
      after = [ "systemd-modules-load.service" ];
      before = [ "display-manager.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/sh -c 'for i in $(seq 1 30); do [ -e /sys/kernel/debug/vgaswitcheroo/switch ] && { echo OFF > /sys/kernel/debug/vgaswitcheroo/switch; exit 0; }; sleep 1; done; exit 1'";
      };
    };

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
  };
}
