# Workstation7 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Hardware details](#hardware-details)
* [Upgrade notes](#upgrade-notes)

## Hardware details
* Gigabyte B550 GAMING X V2 (AM4, PCIe 4.0), AMI BIOS FE (2024-03-22)
* 6-core AMD Ryzen 5 5600
* 32 GB RAM: (4) 8 GB Kingston HyperX Fury DDR4-2400 CL15 (KHX2400C15/8G)
* NVIDIA GeForce GTX 1660 (TU116), 6 GB GDDR5
* Creative Sound BlasterX AE-5 Plus

## Upgrade notes
**RAM**: replace all 4 sticks with (2) 16 GB DDR4-3600 CL16 (or (2) 32 GB)
* 3600 runs FCLK 1:1 at 1800 MHz, Zen 3's sweet spot; 2 sticks hold that speed, 4 often won't
* Don't mix with the old sticks; install in A2/B2 and enable XMP

**GPU**: AMD Radeon RX 9060 XT 16 GB
* Good match for a Ryzen 5 5600 without a CPU bottleneck; 16 GB VRAM
* AMD uses the in-kernel `amdgpu` + Mesa drivers on Linux, with nothing proprietary to keep in sync
* Swap `devices.gpu.nvidia` for `devices.gpu.amd.enable = true;` in `configuration.nix`
* NVIDIA alternative: RTX 5060 Ti 16 GB (PCIe x8 link, fine on PCIe 4.0)
