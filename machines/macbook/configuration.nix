# MacBook configuration
#
# ### Features
# - MacBook laptop deployment
# --------------------------------------------------------------------------------------------------
{ inputs, pkgs, lib, ... }:
let
  # Toggle on (and reboot) for battery savings when not using an external display. Forces the Intel
  # iGPU primary at boot and powers the dGPU off entirely via vga_switcheroo before the display
  # manager starts (idle draw ~20W -> ~9W). Toggle off (and reboot) whenever you need the dGPU for
  # external video (HDMI/USB-C) - T2 Macs have no Linux driver for Apple's USB-C DisplayPort
  # Alt-Mode controller, so external video only works while the dGPU stays in its default power
  # state; forcing the iGPU primary breaks it entirely, regardless of cable/dongle.
  #
  # The amdgpu driver has no runtime PM support for this Polaris chip, so this can only be toggled
  # safely at boot - toggling it live via vga_switcheroo leaves it in a broken half-initialized
  # state (D3hot->D0 resume failure, gfx ring test failure).
  dgpuPowerSave = false;
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

    # Built-in ethernet gets a worse route metric than wifi (600) so that whenever both are up
    # (e.g. dock left plugged in while tethered to a phone hotspot), wifi always wins the default
    # route/DNS instead of a dead or lower-priority ethernet link. Ethernet still works fine as the
    # primary connection when it's the only one active.
    #
    # TEMPORARILY DISABLED 2026-08-09 for HDMI debugging: the combo USB-C dongle (HDMI + Ethernet)
    # re-enumerates enp2s0f1u1 on every Alt-Mode retry cycle, and NetworkManager actively managing
    # this interface is suspected of adding enumeration churn that both causes the typing stutter
    # and interferes with the HDMI Alt-Mode negotiation completing. See
    # claude-plan-to-solve-hdmi-issue.md. Re-enable (remove the `lib.mkIf false`) once confirmed/
    # denied as the cause.
    networking.networkmanager.ensureProfiles.profiles."Wired connection 1" = lib.mkIf false {
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
