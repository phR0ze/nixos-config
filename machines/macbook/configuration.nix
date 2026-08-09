# MacBook configuration
#
# ### Features
# - MacBook laptop deployment
# --------------------------------------------------------------------------------------------------
{ inputs, pkgs, lib, ... }:
let
  # Toggle off temporarily (and reboot) when you need the dGPU for an external display (HDMI/USB-C).
  # The amdgpu driver has no runtime PM support for this Polaris chip, so it can only be safely
  # powered off before the display manager starts at boot - toggling it back on live via
  # vga_switcheroo leaves it in a broken half-initialized state (D3hot->D0 resume failure, gfx
  # ring test failure). Flip this back to true and reboot once you're done with the external display.
  dgpuOff = false;
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

    # The discrete AMD Radeon Pro 555X GPU has no runtime power management support in the amdgpu
    # driver for this Polaris-based chip, so it stays fully powered (D0) at all times, driving idle
    # power draw way up (~20W -> ~9W once switched off). macOS avoids this via its GPU mux driver
    # (gmux), which Linux doesn't support the switching side of, so force the Intel iGPU to be
    # primary at boot and power the dGPU off entirely via vga_switcheroo before the display manager
    # starts. Trades away dGPU acceleration (e.g. for OBS/games) for a large battery life win.
    boot.extraModprobeConfig = ''
      options apple_gmux force_igd=y
    '';
    boot.kernelParams = [ "i915.enable_guc=3" ];
    systemd.services.amdgpu-off = lib.mkIf dgpuOff {
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
    apps.dev.claude.extraInstructions = ''
      ## MacBook (Apple T2, Radeon Pro 555X dGPU)

      This machine is an Apple MacBook Pro hackintosh with a T2 chip and a discrete AMD Radeon
      Pro 555X GPU. The dGPU is powered off at boot via vga_switcheroo (see
      systemd-service amdgpu-off in machines/macbook/configuration.nix) to save power, trading
      away dGPU acceleration. Keep this in mind when changing GPU, power management, or kernel
      module configuration for this machine.
    '';
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
