# ACEPC AK1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Device specs](#device-specs)
* [Install cyberlinux](#install-cyberlinux)

## Device specs
* Core
  * 4-Core Intel Celeron J3455 @ 2.3GHz
  * 4 GB RAM
* Graphics
  * Intel HD Graphics 500 i915
* Drives
  * 64 GB Samsung mmc

# Install cyberlinux

1. Boot Into the `Setup firmware`:  
   1. Press `F7` repeatedly during boot until the boot menu pops up
   2. Select `Enter Setup`
   3. Navigate to `Security >Secure Boot`
   4. Ensure it is `Disabled`

2. Now boot the AK1 from the USB:  
   1. Plug in the [Install USB](../../README.md#install-from-custom-iso)
   2. Press `F7` repeatedly until the boot menu pops up
   3. Select your `UEFI` device entry e.g. `UEFI: USB Flash Disk 1.00`

3. Install `cyberlinux`:  
   1. Once booted into the live environment open a shell
   2. The shell will load the install wizard automatically
   3. TBD
   4. Power off the machine `sudo poweroff`, unplug the USB and then power back up

<!-- 
vim: ts=2:sw=2:sts=2
-->
