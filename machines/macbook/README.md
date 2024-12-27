# MacBook Pro <img style="margin: 6px 13px 0px 0px" align="left" src="../art/logo_36x36.png" />

Documenting the steps I went through to deploy ***NixOS*** onto a MacBook Pro with the T2 chip.

### Quick links
* [.. up dir](../../README.md)
* [Install NixOS](#install-nixos)

## Install NixOS
Note: I installed using an external USB WiFi adapter, mouse and keyboard as the MacBook Pro hardware 
wasn't recognized out of the box. That said it installed fine using external devices.

1. Note you need an Intel based MacBook Pro for this to work

2. Enable booting from external media
   1. Enter recovery mode by pressing `Command + R` when you see the Apple logo for a few seconds
   2. Select your user account and click `Next` then login
   3. Select `Utilities >Startup Security Utility` from the menu at the top
   4. Authenticate as an administrator
   5. Select `Secure Boot >No Security`
   6. Select `Allowed Boot Media > Allow booting from external or removable media`

3. Boot from a bootable NixOS USB drive
   1. Plug in your USB drive
   2. Hold down the Option key while restarting to boot into device selection
   3. Select your USB drive e.g. `EFI Boot`
   3. Install per usual
   4. Choose `/dev/nvme0n1](233.86] - APPLE SSD AP0256M`

## Configure NixOS
The `t2linux` project has some fantastic work wrote up for installing NixOS on a MacBook Pro with the 
T2 chip.

**References**
* [NixOS t2linux wiki](https://wiki.t2linux.org/distributions/nixos/installation/)
* [NixOS t2 iso](https://github.com/t2linux/nixos-t2-iso)
* [NixOS on a MacBookPro](https://www.arthurkoziel.com/installing-nixos-on-a-macbookpro/)
* [MacBookPro - Arch Linux](https://wiki.archlinux.org/title/MacBookPro10,x)

### Install Apple Firmware

1. Add the t2 substituter package cache
   ```nix

   ```




### Install correct WiFi driver
NixOS does not have the correct `brcm` firmware, so run:
```bash
$ sudo mkdir -p /lib/firmware/brcm
$ sudo get-apple-firmware
```


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
