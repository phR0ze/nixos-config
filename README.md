# nixos-config
A simpler approach to deploying a number of different pre-defined system profiles at install time 
using only a bootable NixOS image and network connectivity.

Due to the number of different machines I maintain and how often I change their intended purpose I 
find it essential to be able to take a new system from baremetal to a pre-defined, pre-customized 
purposefully built system profile. NixOS's flakes and profiles provide a fantastic platform on which 
to build this functionality .

### Disclaimer
Any tooling or documentation here comes with absolutely no guarantees or support of any kind. It is 
to be used at your own risk. Any damages, issues, losses or problems caused by the use of any tooling 
or documentation here is strictly the responsiblity of the end user and not the developer/creator of 
this project. This project is highly opinionated and primarily for my own use but your welcome to 
fork it and build on my work.

## Getting started
Using a simple bash installer ***clu*** you can launch a simple wizard to then:

**User choices**
* Choose automatic mode for testing in VMs
* Choose the target install disk
* Choose basic networking options
* Choose basic time date changes
* Choose basic user account options
* Choose autologin options
* Choose a pre-defined system profile
* Choose pre-defined hardware configurations
* Trigger the install

**Installation features**
* Target disk preperation including:
  * Automatic partitioning and mounting
  * Automatic support for EFI or BIOS
* User settings transferred to the underlying `flake.nix` for install

### Install instructions
Using ***clu*** in a few simple steps you can install a fully customized NixOS system.

1. Download the minimal image from [NixOS downloads](https://nixos.org/download.html#nixos-iso)
   ```bash
   $ wget https://channels.nixos.org/nixos-23.11/latest-nixos-minimal-x86_64-linux.iso
   ```

2. Burn the ISO to USB 
   1. Determine the correct USB device
      ```bash
      $ lsblk
      ```
   2. Optionally wipe your USB first e.g. `/dev/sdd`
      ```bash
      $ sudo wipefs --all --force YOUR/DEVICE
      ```
   3. Copy to the dev leaving off the partition
      ```bash
      $ sudo dd bs=4M if=latest-nixos-minimal-x86_64-linux.iso of=YOUR/DEVICE status=progress conv=fsync oflag=direct
      ```

3. Boot from the new USB

4. Download the installer
   ```bash
   $ curl -sL -o clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
   ```

5. Execute the installer
   ```bash
   $ sudo ./clu
   ```

<!-- 
vim: ts=2:sw=2:sts=2
-->
