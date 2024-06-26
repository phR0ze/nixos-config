Dell XPS 13 9310
====================================================================================================

<img align="left" width="48" height="48" src="../../art/logo_256x256.png">
Documenting the steps I went through to deploy <b><i>cyberlinux</i></b> onto the
<a href="https://www.notebookcheck.net/Dell-XPS-13-9310-Core-i7-Laptop-Review-The-11th-Gen-Tiger-Lake-Difference.499291.0.html">Dell XPS 13 9310 Core i7 Laptop</a> <br> This is now a <b>NixOS</b> based system see my <a href="../../">nixos-config</a>
<br><br>

### Quick links
* [.. up dir](../../README.md)
* [Device](#device)
  * [Specs](#Specs)
  * [Open chassis covere](#open-chassis-cover)
  * [SSD Upgrade](#ssd-upgrade)
* [Install cyberlinux](#install-cyberlinux)
* [Configure cyberlinux](#configure-cyberlinux)
  * [Hardware](#hardware)
    * [Flash BIOS to latest](#flash-bios-to-latest)
    * [Audio](#audio)
    * [Graphics](#graphics)
    * [WiFi](#wifi)
    * [Keyboard](#keyboard)
    * [Bluetooth](#bluetooth)
  * [Settings](#settings)
    * [SSH Keys](#ssh-keys)
* [Troubleshooting](#troubleshooting)
  * [Info](#info)
    * [SSD is directly bootable with cyberlinux](#ssd-is-direcctly-bootable-with-cyberlinux)
    * [Ctrl Alt Delete works from cyberlinux installer](#ctrl-alt-delete-works-from-cyberlinux-installer)
  * [Boot from live USB](#boot-from-live-usb)
  * [Stuck on Dell boot logo](#stuck-on-dell-boot-logo)

## Device
**Resources:**
* [Tear down of XPS 9310](https://www.youtube.com/watch?v=Dzf4R3vr22M)
  * Shows battery removal
  * CPU heatsink and fan removal
  * Covers screen replacment as well
  * Covers motherboard replacement as well
  * States that modern laptops like 9310 don't have CMOS battery but instead run directly off the 
  main battery
* [Service Manual PDF](https://dl.dell.com/topicspdf/xps-13-9310-laptop_service-manual_en-us.pdf)

### Specs
* CPU: `Intel 11th Gen EVO Core i7-1185G7@3.00GHz`
* BIOS came with: `2.2.0`
* Microcode Version: `86`
* Native resolution: `1900x1200`
* Video Controller: `Iris Xe`
* Video BIOS: `GOP 1055`
* Audio controller: `Realtek ALC3281-CG`

### Open chassis cover
1. Turn the laptop over
2. Remove the 8 Torx T5 screws
3. Use a guitar pick to gently pry off the case starting from the front two edges and along front
   then lift up the front.

### SSD Upgrade
The SSD options that dell provides are small, slow and way too expensive. I bought the
`Samsung V-NAND SSD 970 EVO Plus NVMe M.2 2TB` SSD from Amazon and it fits and works perfectly.

1. [Remove the chassis cover](#open-chassis-cover)
2. Remove the PH0 screw holding the SSD
3. Remove the old SSD
4. Bend the smaller bracket contraints flat to allow for the larger SSD
5. Install the new SSD and re-assemble

# Install cyberlinux
You need to disable UEFI secure boot in order to install cyberlinux as only the Ubuntu factory
firmware that comes with the machine will be cryptographically signed for the machine.

1. Boot Into the `Setup firmware`:  
   1. Press `F2` while booting (no need to press `Fn` key)
   2. In the left hand navigation select `Boot Configuration`
   3. On the right side scroll down to `Secure Boot`
   4. Flip the toggle on `Enable Secure Boot` to `OFF`
   5. Select `Yes` on the Secure Boot disable confirmation
   6. In the left hand navigation select `Storage`
   7. Select `AHCI/NVMe` rather than `RAID On`
   8. Select `APPLY CHANGES` at the bottom
   9. Select `OK` on the Apply Settings Confirmation page
  10. Select `EXIT` bottom right of the screen to reboot

2. Now boot from the USB:  
   1. Plug in the [Install USB](../../README.md#install-from-custom-iso)  
   2. Press `F2` while booting  
   3. Select your `UEFI` USB device  

3. Install `cyberlinux`:  
   1. Once booted into the live environment open a shell
   2. The shell will load the install wizard automatically
   3. Choose the `dell-xps-13` machine option then complete the wizard
   4. Power off the machine `sudo poweroff`, unplug the USB and then power back up

# Configure cyberlinux
* [Arch Linux Dell XPS 13 (9310)](https://wiki.archlinux.org/title/Dell_XPS_13_(9310))

First results:
* Pre login
  * Machine automatically started when the lid was opened
  * LXDM login is shown and looks great and logs in correctly
* Post login
  * Set display dimness almost to the bottom and it still looks great
  * Battery seems to be detected when charging and when plugged in
  * Conky started working after BIOS firmware update
  * Audio works after firmware install and restart
  * Audio keyboard buttons work
* Problems
  * Locks up and keyboard input doesn't work see [Keyboard](#keyboard)

## Hardware

### Flash BIOS to latest
`fwupd` is a simple daemon that allows large vendors like Dell and Logitech to distribute firemware 
to Linux devices using what they call `Linux Vendor Firmware Service (LVFS)`

References:
* [Linux Vendor Firmware Service Device Update List](https://fwupd.org/lvfs/devices/)
* [Arch Linux Wiki](https://wiki.archlinux.org/title/Flashing_BIOS_from_Linux#fwupd)

1. Install fwupd
   ```bash
   $ sudo pacman -S fwupd
   ```
2. Check for updates
   ```bash
   $ sudo fwupdmgr refresh
   $ sudo fwupdmgr get-updates
   ```
3. Apply updates
   ```bash
   $ sudo fwupdmgr update
   ```

Upgraded to `3.0.4`

## Audio
Included in the latest cyberlinux builds

Requires the `alsa-firmware` and `sof-firmware` packages to work. After reboot you should be good.
* Volume Control buttons seem to work great

## Graphics
[Hardware Video Acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)

1. Install hardware acceleration drivers:
   ```bash
   $ sudo pacman -S intel-media-driver libvdpau-va-gl libva-utils vdpauinfo
   ```
2. Valid output from `vainfo` should show your acceleration is working
   ```bash
   $ vainfo
   ```
3. Valid output from `vdpauinfo` should show your acceleration is working
   ```bash
   $ vdpauinfo
   ```

## WiFi
Works perfectly with NetworkManager and the applet. All you have to do is just left click on the 
`nm-applet` icon in the tray and select your WiFi SSID. Entry your password and you should be greeted 
with a connection pop up.

## Keyboard
99.9% of the time the keyboard works great. 0.01% of the time it freezes and doesn't respond at all 
or if you Alt+F4 and app it freezes immediately. For this reason I just avoid Alt+F4 and if it every 
freezes I have added a Restart icon to my launcher and since the mouse still works I'll just restart 
and it its good

## Bluetooth
BlueTooth seems to work fine out of the box

1. Install Bluetooth management tool and pulse audio plugin
   ```bash
   $ sudo pacman -S blueman bluez-utils pulseaudio-bluetooth
   ```
2. Enable Bluetooth
   ```bash
   $ sudo systemctl enable bluetooth
   $ sudo systemctl start bluetooth
   ```
3. Pair with device
   * Left click the Bluetooth icon in the tray
   * Click `Search` in the Bluetooth Devices window that pops up
   * Select your device then click the key button to pair

## Settings
Custom changes not included in cyberlinux builds

### SSH Keys
Copy over ssh keys
```bash
$ scp -r USER@IP-ADDRESS:~/.ssh .
```

### Configure hotkeys
* Set `insert` as drop down terminal activation key
  * Navigate to `Apps >Settings >Keyboard`
  * Select the `Application Shortcuts` tab
  * Scroll down to `xfce4-terminal --drop-down` and click `Remove`
  * Click `Add` and enter `xfce4-terminal --drop-down` and set `insert`

### Configure git
* Set user name `git config user.name <USER_NAME>`
* Set user email `git config user.email <EMAIL_ADDRESS>`

### Clone any data
* Documents
  ```bash
  $ rmdir ~/Documents
  $ git clone ssh://USER@IP-ADDRESS:/mnt/storage/Documents
  ```
* Pictures
  ```bash
  $ cd ~/Pictures
  $ git clone ssh://USER@IP-ADDRESS:/mnt/storage/Pictures/2021
  $ git clone ssh://USER@IP-ADDRESS:/mnt/storage/Pictures/2022
  ```

# Troubleshooting

## Info

### SSD is directly bootable with cyberlinux
`cyberlinux` makes your SSD directly bootable from the BIOS via its UEFI support. This means when 
doing a one-time boot with `F12` you can simply select the SSD unlike the default Dell Ubuntu install 
which only boots via its separate `ubuntu` bootloader entry.

### Ctrl Alt Delete works from cyberlinux installer
Once the `cyberlinux` install is complete you can simply hit `Ctrl+Alt+Delete` to reboot the device. 
It will seem to take a couple seconds to entry reset mode but it always works.

## Boot from live USB
1. Plug your live USB stick into a USB-C adapter and then into your laptop
2. Press the power button to boot then start pressing `F12` (no need to press `Fn` key)
3. Once the `One-Time Boot Settings` loads select your USB drive and press `Enter`

## Stuck on Dell boot logo
According to the [Dell XPS 13 9310 tear down](https://www.youtube.com/watch?v=Dzf4R3vr22M) video the 
9310 doesn't have a CMOS battery but rather simply uses the main battery. This means that to clear 
the CMOS out all you have to do is disconnect the main battery and wait for some time for the CMOS to 
discharge.

NOTE: this solution will supposedly fix a lot of BIOS issues. However my system was actually 
suffering from a 2 amber 4 white light issue which is bad RAM which is soldered to the motherboard. 
So calling support for this one.

1. [Remove the chassis cover](#open-chassis-cover)
2. Disconnect the main battery
3. Flip the unit over on a non-metalic surface 
4. Hold the power down for at least 30sec
5. Re-connect the main battery

<!-- 
vim: ts=2:sw=2:sts=2
-->
