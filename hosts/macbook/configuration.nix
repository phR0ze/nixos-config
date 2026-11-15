# MacBook configuration
#
# ### Features
# - MacBook laptop deployment
# --------------------------------------------------------------------------------------------------
{ inputs, pkgs, lib, ... }:
let
  # dGPU power savings vs HDMI/USB-C video toggle - mutually exclusive modes, boot-only (not
  # hot-toggleable). See README.md "dGPU power saving vs HDMI/USB-C video" for full details.
  dgpuPowerSave = false;

  # t2 kernel with a patch set that applies to the current nixpkgs kernel - nixos-hardware's own
  # pinned set no longer does. See linux-t2.nix for the full rationale and how to drop it.
  t2Kernel = import ./linux-t2.nix {
    inherit pkgs;
    nixos-hardware = inputs.nixos-hardware;
  };
in
{
  imports = [
    ./hardware-configuration.nix

    # t2 modules from nixos hardware are pinned in the flake
    inputs.nixos-hardware.nixosModules.apple-t2
  ];

  config = {
    # Override the apple-t2 module's own kernelPackages, see `t2Kernel` above
    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor t2Kernel);

    host.boot.efi = true;
    host.desktop.xfce.develop = true;
    host.resolution = { x = 1920; y = 1200; } ;
    system.x11.xft.dpi = lib.mkForce 120;         # Increase the default DPI size

    # UHD 630 iGPU is always present; the AMD Baffin dGPU is only driven in the default mode - in
    # `dgpuPowerSave` it gets powered off below, so loading amdgpu early would be pointless
    devices.gpu.intel.enable = true;
    devices.gpu.amd.enable = !dgpuPowerSave;

    # Fix default power governor to run at a lower frequency and boost as needed
    powerManagement.cpuFreqGovernor = "schedutil";

    # Blacklist open source broadcom drivers
    boot.blacklistedKernelModules = [ "b43" "bcma" ];

    # The T2 chip's internal iBridge controller exposes a USB CDC-NCM "Ethernet" gadget
    # (enp2s0f1u1) with carrier permanently on but no real link behind it. NetworkManager
    # endlessly retries DHCP on it, which keeps nm-applet's tray icon spinning even though
    # the real (WiFi) connection is fine. Leave it unmanaged so NM stops trying to activate it.
    networking.networkmanager.unmanaged = [ "interface-name:enp2s0f1u1" ];

    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    # Forces the Intel iGPU primary - nixos-hardware writes the apple-gmux force_igd modprobe conf
    hardware.apple-t2.enableIGPU = dgpuPowerSave;
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

    # Wi-Fi and Bluetooth firmware, extracted declaratively by nixos-hardware's brcm-firmware
    # derivation: a fixed-output build that pulls the macOS recovery image via macrecovery and
    # unpacks it in a Linux VM, so it needs KVM and a multi-GB download - the substituters below
    # may have it prebuilt. This replaces the old hand-rolled derivation that read
    # /lib/firmware/brcm off the live host, an absolute path outside the flake tree that forced
    # `--impure` on every macbook build.
    hardware.apple-t2.firmware.enable = true;
    hardware.apple-t2.firmware.version = "ventura";

    # Touch Bar - nixos-hardware dropped its own enableTinyDfr for the upstream nixpkgs module
    hardware.apple.touchBar.enable = true;

    nix.settings = {
      trusted-substituters = [ "https://t2linux.cachix.org" "https://cache.soopy.moe" ];
      trusted-public-keys = [
        "t2linux.cachix.org-1:P733c5Gt1qTcxsm+Bae0renWnT8OLs0u9+yfaK2Bejw="
        "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo="
      ];
    };

    apps.media.obs.enable = true;
    apps.network.rustdesk.autostart = false;
  };
}
