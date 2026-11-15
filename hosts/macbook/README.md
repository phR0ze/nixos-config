# MacBook Pro <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

Documenting the steps I went through to deploy ***NixOS*** onto a MacBook Pro with the T2 chip. This 
configuration enabled full functionality including: touch bar, WiFi, ethernet, speaker sound and HDMI 
output with audio, keyboard, and touch pad.

### Quick links
* [.. up dir](../../README.md)
* [Install NixOS](#install-nixos)
  * [Enable booting from exteranl media](#enable-booting-from-external-media)
  * [Install from bootable USB](#install-from-bootable-usb)
* [Configure NixOS](#configure-nixos)
  * [Wi-Fi and Bluetooth firmware](#wi-fi-and-bluetooth-firmware)
  * [Other config](#other-config)
* [dGPU power saving vs HDMI/USB-C video](#dgpu-power-saving-vs-hdmiusb-c-video)

## Install NixOS
Note: I originally installed using an external USB WiFi adapter, mouse and keyboard as the MacBook 
Pro hardware wasn't recognized out of the box. That said it installed fine using external devices.

***NOTE*** you need an Intel based MacBook Pro with administrator access for this to work.

* 6-core Intel Core i7-8750H
* Broadcom 802.11ac WiFi BCM4364 rev 3
* Intel CoffeeLake-H GT2 [UHD Graphics 630]
* AMD Baffin [Radeon RX 460/560D Pro 450/455/460/555/555X/560/560X]

### Enable booting from external media
MacBooks are locked down by default and only allow booting from the internal HDD with a signed ISO. 
You have to specifically allow booting from external media and disable secure boot.

1. Enter recovery mode by holding down `Command + R` when you see the Apple logo
2. Select your user account and click `Next` then login
3. Select `Utilities >Startup Security Utility` from the menu at the top
   * Authenticate as an administrator when prompted
4. Select `Secure Boot >No Security`
5. Select `Allowed Boot Media > Allow booting from external or removable media`

### Install from bootable USB
1. Plug in your USB drive
2. Hold down the `option` key while restarting to launch device selection utility
3. Select your USB drive e.g. `EFI Boot`
4. Install per usual choosing the internal disk as the target
   * e.g. `[/dev/nvme0n1](233.86) - APPLE SSD AP0256M`

## Configure NixOS
Apple's T2 chip based MacBooks are not fully supported out of the box by the Linux kernel; however 
the `t2linux` project has done some fantastic work to add support.

**References**
* [NixOS t2 iso](https://github.com/t2linux/nixos-t2-iso)
* [NixOS t2linux wiki](https://wiki.t2linux.org/distributions/nixos/installation/)
* [NixOS on a MacBookPro](https://www.arthurkoziel.com/installing-nixos-on-a-macbookpro/)
* [MacBookPro - Arch Linux](https://wiki.archlinux.org/title/MacBookPro10,x)

### Wi-Fi and Bluetooth firmware
NixOS doesn't ship the `brcm` firmware this hardware needs; it has to be extracted from an upstream
macOS recovery image. `nixos-hardware`'s `apple-t2` module does this declaratively, so there is no
longer any manual wizard step or host path involved.

```nix
hardware.apple-t2.firmware.enable = true;
hardware.apple-t2.firmware.version = "ventura";
```

This builds `brcm-firmware`, a fixed-output derivation that downloads the recovery image with
`macrecovery` and extracts both the Wi-Fi and the Bluetooth firmware inside a Linux VM. Notes:

* It needs KVM, so it has to build on the MacBook itself, and the recovery image is a multi-GB
  download. The `t2linux.cachix.org` / `cache.soopy.moe` substituters configured in
  `configuration.nix` may already have it prebuilt.
* The derivation is `license = unfree`, which `modules/nixpkgs.nix`'s `allowUnfreePredicate`
  already permits.
* `"ventura"` matches what the old T2Linux `get-apple-firmware` wizard recommended for this model
  (`3. Download a macOS Recovery Image...` -> `6. Ventura (13) - RECOMMENDED`). The module's own
  default is `"sonoma"`.

This replaced an earlier hand-rolled approach: running `sudo get-apple-firmware` once to populate
`/lib/firmware/brcm`, then wrapping that directory in a derivation with `src = /lib/firmware/brcm`.
Because that's an absolute path outside the flake's source tree, pure evaluation can't see it, and
every macbook build needed `--impure` - which the repo otherwise forbids. The
`packages/apple/` wrapper for the wizard script and its `python3` / `dmg2img` dependencies are
gone with it.

### Other config
I saw these in the reference configurations. I did end up using the `schedutil` setting and
blacklisted the broadcom drivers, but used the t2linux firmware for the WiFi (see above).

1. Enable propriety broadcom driver
   ```nix
   boot.kernelModules = [ "wl" ];
   boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
   ```
2. Blacklist broadcom drivers
   ```nix
   boot.blacklistedKernelModules = [ "b43" "bcma" ];
   ```
3. Fix default power governor to run at a lower frequency and boost as needed
   ```nix
   powerManagement.cpuFreqGovernor = "schedutil";
   ```
4. Power off the discrete AMD Radeon Pro 555X GPU (Polaris, no amdgpu runtime PM support) via
   `vga_switcheroo` since it otherwise stays powered on at all times, at a real idle power cost
   (roughly 20W -> 9W). This forces the Intel iGPU to be primary and disables the dGPU before the
   display manager starts (see `configuration.nix` for `hardware.apple-t2.enableIGPU` + the
   `amdgpu-off.service`). Trades away dGPU acceleration for battery life. See
   [dGPU power saving vs HDMI/USB-C video](#dgpu-power-saving-vs-hdmiusb-c-video) below for the
   full trade-off and how to switch modes.
   * `dgpu-status`: `sudo cat /sys/kernel/debug/vgaswitcheroo/switch`
   * To temporarily re-enable the dGPU: `sudo systemctl stop amdgpu-off && echo ON | sudo tee /sys/kernel/debug/vgaswitcheroo/switch`
     (re-run `clu update macbook` to restore the off-at-boot behavior)
   * Known caveat: possible black screen after resume from suspend; `i915.enable_guc=3` is set as
     a mitigation. If suspend/resume issues appear, try `i915.enable_guc=2` instead.

## dGPU power saving vs HDMI/USB-C video

The discrete AMD Radeon Pro 555X (Polaris, no `amdgpu` runtime PM support) stays powered on at all
times unless forced off, costing roughly 20W -> 9W of idle draw. `machines/macbook/configuration.nix`
exposes this as a toggle, `dgpuPowerSave` (currently `false`), rather than an unconditional setting,
because **the two modes are mutually exclusive**:

* **`dgpuPowerSave = true`** (battery savings): forces the Intel iGPU primary at boot and powers the
  AMD dGPU off entirely via `vga_switcheroo` before the display manager starts
  (`hardware.apple-t2.enableIGPU` + the `amdgpu-off.service`), plus `i915.enable_guc=3` as a suspend/resume
  mitigation. **Expected result: external video over HDMI/USB-C does not work.** T2 Macs have no
  Linux driver for Apple's USB-C DisplayPort Alt-Mode controller, so external video only works while
  the dGPU stays in its default power state — forcing the iGPU primary breaks Alt-Mode negotiation
  entirely, regardless of cable/dongle (the dongle enumerates only as a USB "Billboard" device, the
  USB-IF fallback class for failed Alt-Mode negotiation).
* **`dgpuPowerSave = false`** (default): dGPU stays in its normal power state. **Expected result:
  HDMI/USB-C video works**, at the cost of the extra ~11W idle draw.

The `amdgpu` driver has no runtime PM support for this chip, so this can only be toggled safely
**at boot** — toggling `vga_switcheroo` live leaves the dGPU in a broken half-initialized state
(D3hot->D0 resume failure, gfx ring test failure). Always change `dgpuPowerSave`, run
`clu update macbook`, and do a full reboot (not just `switch`) to change modes.

**Saved a known-good HDMI generation**: generation 49 boots with `dgpuPowerSave = false` and is kept
around specifically so the working-HDMI mode can be selected directly from the bootloader/generation
list, without needing to edit config and rebuild every time external video is needed.

### Unrelated but easily confused: NetworkManager vs. combo USB-C dongle

Separately from the dGPU state, a combo USB-C dongle (HDMI + Ethernet) surfaced a second issue: with
`networking.networkmanager.ensureProfiles.profiles."Wired connection 1"` actively managing the
dongle's `enp2s0f1u1` ethernet interface, every USB Alt-Mode retry cycle re-enumerated the hub and
triggered NetworkManager churn on that interface, which both caused a typing stutter and interfered
with the HDMI Alt-Mode negotiation completing. This was fixed by disabling that profile
(`lib.mkIf false`) and was confirmed independent of the `dgpuPowerSave` state (tested with
`dgpuPowerSave = false` both before and after the fix). The disabled profile's original purpose —
giving wifi a better (lower) route metric than a dead/lower-priority wired link, e.g. when a dock is
left plugged in while tethered to a phone hotspot — is a known, currently-accepted trade-off; ethernet
still works fine as the primary connection when it's the only one active.

## Configure System
XFCE's Window Scaling option looked great until I opened another application that didn't support it. 
A better option seems to be to just drop down the resolution to `1920x1200` which is a shame but I'm 
not running anything needing greater than HD resolution for now.

1. Launch `Apps >Settings >Display` then set `1920x1200`
2. Launch the `Appearance` app switch to `Fonts` and set `Custom DPI setting` to `120`

<!-- 
vim: ts=2:sw=2:sts=2
-->
