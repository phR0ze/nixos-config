# nixos-config
A simpler approach to deploying a number of different pre-defined system profiles at install time 
using only a bootable NixOS image and network connectivity.

Due to the number of different machines I maintain and how often I change their intended purpose I 
find it essential to be able to take a new system from baremetal to a pre-defined, purposefully built 
system serving in it's intended function as effortlessly as possible. NixOS's Nix and flakes 
integration provides a fantastic platform on which to build this functionality.

### Disclaimer
Any tooling or documentation here comes with absolutely no guarantees or support of any kind. It is 
to be used at your own risk. Any damages, issues, losses or problems caused by the use of any tooling 
or documentation here is strictly the responsiblity of the end user and not the developer/creator of 
this project. This project is highly opinionated and primarily for personal use but your welcome to 
fork it and build on my work.

### Quick links
* [Getting Started](#getting-started)
  * [Install instructions](#install-instructions)
  * [Update instructions](#update-instructions)
* [Advanced use cases](#advanced-use-cases)
  * [Build the live ISO for installation](#build-the-live-iso-for-installation)
* [Backlog](#backlog)

## Getting started
***clu***, is a simple bash script providing an install wizard to:

* Prompt you for a few simple customization selections
* Automate the annoying tasks like
  * disk paritioning and mounting
  * generation of nixos hardware configuration
  * transfering install time customizations to the underlying nix flake
  * triggering the install of the complete system via nix flakes

### Install instructions

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

3. Boot from the new USB and start a nix shell
   ```bash
   $ nix-shell -p git jq
   ```

4. Clone this repo
   ```bash
   $ git clone https://github.com/phR0ze/nixos-config
   ```

5. Execute the installer
   ```bash
   $ cd nixos-config
   $ chmod +x clu
   $ sudo ./clu install
   ```

### Update instructions
After installing your system you'll need to make changes from time to time. The `clu` automation will 
have copied the original configuration to `/etc/nixos`.

1. Change directory to the configuration folder
   ```bash
   $ cd /etc/nixos
   ```

2. Make changes as desired
  
3. Commit or stage your configuration changes so they are visible to nix flakes
   ```bash
   $ git add .
   ```

4. Update your system with the configuration changes
   ```bash
   # Optionally first upgrade your flake.lock
   $ nix flake update

   # Apply your configuration changes
   $ sudo ./clu update system
   ```

## Advanced use cases
Most linux users, especially those coming from Arch Linux, will immediately be interested in how they 
can extend and make this their own. Following best practices across the NixOS community I'm breaking 
down my configuration into modules. This allows for composability for higher level concepts like 
profiles. I'm organizing my modules to follow the nix options for the most part.

### Build the live ISO for installation
NixOS has a lot of reusable automation built into it. In the Arch world typically you have to start 
from scratch and build your own automation if you want control over how its being built. In the Nix 
world though this already exists.

1. Clone this repo
   ```bash
   $ git clone https://github.com/phR0ze/nixos-config
   ```

2. Modify the ISO profile as desired
   ```bash
   $ vim profiles/iso/default.nix
   ```

3. Commit or at the least stage your changes so Nix will see them
   ```bash
   $ git add .
   ```

4. Now build the iso
   ```bash
   $ ./clu build iso
   ```

5. The ISO will end up in `result/iso/`

## Backlog
* [ ] Create ISO with full live GUI environment

## Sometime
* [ ] Include missing hicolor icons - fall back icons not working `XDG_ICON_DIRS`
* [ ] Conflicts: file names, directory names with different modes or permissions
* [ ] XFCE: Move launcher to top
* [ ] XFCE: Move app panel to bottom
* [ ] Choose default resolution for system
* [ ] Add `nix-prefetch fetchFromGitHub --owner hrsh7th --repo nvim-cmp --rev 768548bf4980fd6d635193a9320545bb46fcb6d8`
* [ ] Add vim-colorize plugin
* [ ] Configure `git config --global user.name`
* [ ] Configure `git config --global user.email`
* [ ] Configure `git config --global --add safe.directory /etc/nixos`
* [ ] Change nix flake symbol to blue in vim colorizer plugin
* [ ] `sudo nix-channel --list` is showing stuff
* [ ] Remove `/etc/nixos/etc/nixos`
* [ ] clu to update `flake.nix` with user selection
* [ ] Change the tty autologin welcome message
* [ ] Change the kernel boot colors 

* Configs to circle back to
  * https://github.com/danth/stylix
  * https://github.com/benetis/dotfiles-1/blob/master/nixos-config/machines/desktop/modules/android.nix
  * https://github.com/benetis/dotfiles-1/blob/master/nixos-config/machines/desktop/modules/hardened-chromium.nix
  * https://github.com/thexyno/nixos-config/blob/main/nixos-modules/hardware/laptop.nix
  * https://github.com/jakehamilton/config/blob/main/modules/nixos/desktop/addons/gtk/default.nix
  * https://github.com/librephoenix/nixos-config

## Completed
* [x] XFCE profiles
  * [x] Fix nerd fonts in shell
  * [x] Autologin options plumbed in
  * [x] Port cyberlinux cli packages over
  * [x] Adding solarized dircolors theme
  * [x] Add starship command prompt for all users
  * [x] Install neovim as default editor and customize
  * [x] Add the flake nixpkgs to the `NIX_PATH`
* [x] Nix `files` options
  * [x] Implemented `files.user`, `files.any`, `files.root`, `files.all`
  * [x] Support installing arbitrary files and directories
* [x] clu system automation
  * [x] `./clu registry list`
  * [x] `./clu clean store` wrapper for `nixcl="sudo nix-store --optimise -v && sudo nix-collect-garbage -d";`
* [x] ISO and clu installer automation
  * [x] ISO nix store is used to pre-populate the target system
  * [x] Inject clu into bootable ISO and auto launch it
  * [x] clu to clone nixos-config repo and install it
  * [x] Pass automation and user set options
  * [x] Warn user before destructive disk operations
  * [x] Default root and user passwords and print them out during install

<!-- 
vim: ts=2:sw=2:sts=2
-->
