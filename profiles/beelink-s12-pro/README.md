![cyberlinux logo](../../art/logo_32x32.png) Beelink S12 Pro
====================================================================================================
Documenting the steps I went through to deploy ***cyberlinux*** onto the
[Beelink S12 Pro](https://www.notebookcheck.net/Intel-N100-performance-debut-Beelink-Mini-S12-Pro-mini-PC-review.758950.0.html)

WIP while I switch over to NixOS

### Quick links
* [Install cyberlinux](#install-cyberlinux)
* [Configure cyberlinux](#configure-cyberlinux)
  * [WiFi](#wifi)
  * [Graphics](#graphics)
  * [Kodi](#kodi)
  * [Warcraft 2](#warcraft-2)

# Install cyberlinux

1. Boot the S12 from the USB:
   1. Plugin in the USB built from [Build the live ISO for installation](../../README.md#build-the-live-iso-for-installation)
   2. Press `F7` repeatedly until the boot menu pops up
   3. Select your `UEFI` device entry e.g. `UEFI: KingstonDataTraveler 2.01.00`

3. Install `cyberlinux`
   1. see [Install from custom ISO](../../README.md#isntall-from-custom-iso)

# Configure cyberlinux

## WiFi
NetworkManager make configuring Wifi a breeze

1. Left click on the NetworkManager applet in the system tray
2. Select your WiFi endpoint
3. Enter in your password and done

## Graphics
[Hardware Video Acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)
Note: for the [Intel 12th Gen Alder Lake UHD Graphics](https://www.notebookcheck.net/Intel-UHD-Graphics-24EUs-Alder-Lake-N-GPU-Benchmarks-and-Specs.760772.0.html) we'll need to use the `intel-media-driver` which you can see from its release info
[Intel Media Driver 23.4.3](https://github.com/intel/media-driver/releases/tag/intel-media-23.4.3) supports Alter Lake. 

Alder Lake N100 has an integrated `UHD Graphics` GPU. However by default the `i915` driver was used 
as shown with `inxi` i.e. `Intel Alder Lake-N [UHD Graphics] driver: i915`

1. Install hardware acceleration drivers:
   ```bash
   $ sudo pacman -S intel-media-driver libva libva-utils vdpauinfo mesa-utils
   $ sudo pacman -S libva-intel-driver libvdpau-va-gl libva-utils vdpauinfo
   ```
2. Valid output from `vainfo` should show your acceleration is working
   ```bash
   $ vainfo
   ```
3. Valid output from `vdpauinfo` should show your acceleration is working
   ```bash
   $ vdpauinfo
   ```

## Kodi
Optional example step for configuring the use of a pre-existing local NFS share for media on Kodi

1. Hover over selecting `Remove this main menu item` for those not used `Muic Videos, TV, Radio, Games, Favourites`  
2. Add NFS shares as desired  
3. Navigate to `Movies > Enter files selection > Files >Add videos...`  
4. Select `Browse >Add network location...`  
5. Select `Protocol` as `Network File System (NFS)`  
6. Set `Server address` to your target e.g. `192.168.1.3`  
7. Set `Remote path` to your server path e.g. `srv/nfs/Movies`  
8. Select your new NFS location in the list and select `OK`  
9. Select `OK` then set `This directory contains` to `Movies`  
10. Set `Choose information provider` and set `Local information only`  
11. Set `Movies are in separate folders that match the movie title` and select `OK`  
12. Repeat for any other NFS share paths your server has  

## Warcraft 2
Optional example step for configuring a wine based game on your system

1. Follow the [instructions here](../../system/wine/README.md#install-warcraft-2)
2. Create the bash script `~/bin/warcraft2`
   ```bash
   #!/bin/bash

   WINEARCH=win32 WINEPREFIX=~/.wine/prefixes/warcraft2 wine ~/.wine/prefixes/warcraft2/drive_c/GOG\ Games/Warcraft\ II\ BNE/Warcraft\ II\ BNE_dx.exe
   ```
3. Make the script executable `chmod +x ~/bin/warcraft2`
4. Launch warcaft by pressing Super+R and entering `warcraft2`

<!-- 
vim: ts=2:sw=2:sts=2
-->
