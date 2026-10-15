# Family11 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Hardware details](#hardware-details)
* [Upgrade notes](#upgrade-notes)

## Hardware details
* MSI A320M PRO-M2 V2 (MS-7B84) (AM4), AMI BIOS 3.4Y (2020-06-30)
* 6-core AMD Ryzen 5 2600X
* (2) slots total
  * 16 GB RAM: (2) 8 GB Kingston HyperX Fury DDR4-2400 CL15 (KHX2400C15/8G)
* NVIDIA GeForce GTX 1660 (TU116)
* RTL8822BU USB WiFi (0bda:b812) via in-kernel `rtw88_8822bu` driver

## Upgrade notes
The only potential upgrade for this system would be a modest GPU boost.

**GPU**: AMD Radeon RX 6600 8 GB
* Good match for a Ryzen 5 2600X (Zen+) without a CPU bottleneck
* AMD uses the in-kernel `amdgpu` + Mesa drivers on Linux, with nothing proprietary to keep in sync
* Swap `devices.gpu.nvidia` for `devices.gpu.amd.enable = true;` in `configuration.nix`
* NVIDIA alternative: RTX 3050 8 GB
* Board's PCIe x16 slot is Gen3 (B350/A320 era) - either card runs fine, well under Gen3 x16 bandwidth
