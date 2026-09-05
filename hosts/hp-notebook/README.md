# HP Notebook 15-af123c1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Hardware](#hardware)
  * [Bios Access](#bios-access)

## Hardware
* HP Notebook 15-AF123CL
  * Product# P1B07UA#ABA
  * CPU: AMD A8-7410 2.2 GHz (4 core)
  * Touchscreen 15.6" 1366x768
  * 5 GB DDR3-SDRAM
  * Samsung SSD 840 Pro
  * AMD Radeon R5 graphics
  * SD, SDHC, SDXC
  * DVD Super Multi
  * Wi-Fi 4 802.11n
    * Broadcom BCM43142 rev 01
  * LAN 100 Mbps
  * Bluetooth 4.0
  * Battery 3 cell 2800 mAh
    - HP HS04
    - HSTNN-LB6U

### Bios Access
* Press `F10` at boot
* Disable the TPM in the bios and hide it to avoid odd timeout failures with `/dev/tpmrm0`

### WiFi configuration
Broadcom is notorious for poor support on Linux but there is a closed source driver available using 
the option `hardware.broadcom.enable = true` on NixOS.

```nix
{
  networking.networkmanager.enable = true;
  hardware.broadcom.enable = true;
}
```
