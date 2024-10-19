# ACEPC AK1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

Documenting the steps I went through to deploy, my **NixOS** based system ***cyberlinux***
onto the [ACEPC AK1](https://www.techradar.com/reviews/acepc-ak1-mini-pc).

### Quick links
* [.. up dir](../../README.md)
* [Install cyberlinux](#install-cyberlinux)
* [Configure cyberlinux](#configure-cyberlinux)
  * [WiFi](#wifi)
  * [General](#general)
  * [Graphics](#graphics)
  * [Kodi](#kodi)
  * [Warcraft 2](#warcraft-2)

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
   3. Choose the `acepc-ak1` machine option then complete the wizard
   4. Power off the machine `sudo poweroff`, unplug the USB and then power back up

# Configure cyberlinux

## WiFi
NetworkManager makes configuring Wifi a breeze

1. Left click on the NetworkManager applet in the syste tray
2. Select your WiFi endpoint
3. Enter in your password and your done

## General
1. Copy over ssh keys to `~/.ssh`

## Graphics
Graphics are taken care of automatically by selecting the correct profile during install

## Kodi
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
1. Follow the [instructions here](https://github.com/phR0ze/tech-docs/gaming/warcraft2/README.md)
2. Create the bash script `~/bin/warcraft2`
   ```bash
   #!/usr/bin/env bash

   WINEARCH=win32 WINEPREFIX=~/.wine/prefixes/warcraft2 wine ~/.wine/prefixes/warcraft2/drive_c/GOG\ Games/Warcraft\ II\ BNE/Warcraft\ II\ BNE_dx.exe
   ```
3. Make the script executable `chmod +x ~/bin/warcraft2`
4. Launch warcaft by pressing Super+R and entering `warcraft2`

<!-- 
vim: ts=2:sw=2:sts=2
-->
