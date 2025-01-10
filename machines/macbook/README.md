# MacBook Pro <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

Documenting the steps I went through to deploy ***NixOS*** onto a MacBook Pro with the T2 chip. This 
configuration enabled full functionality including: touch bar, WiFi, ethernet, speaker sound and HDMI 
output with audio, keyboard, and touch pad.

### Quick links
* [.. up dir](../../README.md)
* [Install NixOS](#install-nixos)

## Install NixOS
Note: I installed using an external USB WiFi adapter, mouse and keyboard as the MacBook Pro hardware 
wasn't recognized out of the box. That said it installed fine using external devices.

***NOTE*** you need an Intel based MacBook Pro with administrator access for this to work.

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

### Install get-apple-firmware script
Download and install the T2Linux project's `get-apple-firmware` script from their github repo using 
the following nix package called from your `configuration.nix`.

**configuration.nix**
```nix
environment.systemPackages = [
  pkgs.python3
  pkgs.dmg2img
  (pkgs.callPackage ../../modules/hardware/apple.nix {})
];
```

**apple.nix** from https://github.com/t2linux/wiki/blob/master/docs/tools/firmware.sh depends on 
`python3` and `dmg2img` to work properly.
```nix
{ stdenvNoCC, fetchurl, lib }: stdenvNoCC.mkDerivation (final: {
  pname = "get-apple-firmware";
  version = "fe8c338e6cf1238a390984ba06544833ab8792d3";
  src = fetchurl {
    url = "https://raw.github.com/t2linux/wiki/${final.version}/docs/tools/firmware.sh";
    hash = "sha256-DYghvLnG3DO8WmLIrT4p5yzCDWRevp3vx0wYtdTLyeY=";
  };

  dontUnpack = true;

  buildPhase = ''
    mkdir -p $out/bin
    cp ${final.src} $out/bin/get-apple-firmware
    chmod +x $out/bin/get-apple-firmware
  '';

  meta = {
    description = "A script to get needed firmware for T2linux devices";
    homepage = "https://t2linux.org";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ soopyc ];
    mainProgram = "get-apple-firmware";
  };
})
```

### Install Apple Firmware
See flake changes

### Install correct WiFi driver
NixOS does not have the correct `brcm` firmware, so we have to extract it from the upstream macOS 
recovery image and install it from there using the T2Linux project's `get-apple-firmware` script.

1. Launch the T2Linux project's `get-apple-firmware` wizard 
   ```bash
   $ sudo get-apple-firmware
   ```
2. Choose `3. Download a macOS Recovery Image from Apple and extract the firmware from there`
3. Choose `6. Ventura (13) - RECOMMENDED` 
4. Add a package build block to your `configuration.nix` to install the driver
   ```nix
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
   ```

### Notes not used
I saw these in the reference configurations, but didn't end up using them because I didn't see them 
in the T2Linux changes else they have them in their hardware configuration which I haven't examined 
yet.

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

## Configure System
XFCE's Window Scaling option looked great until I opened another application that didn't support it. 
A better option seems to be to just drop down the resolution to `1920x1200` which is a shame but I'm 
not running anything needing greater than HD resolution for now.

1. Launch `Apps >Settings >Display` then set `1920x1200`
2. Launch the `Appearance` app switch to `Fonts` and set `Custom DPI setting` to `120`

<!-- 
vim: ts=2:sw=2:sts=2
-->
