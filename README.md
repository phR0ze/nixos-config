# nixos-config
A simpler approach to deploying a number of different pre-defined system profiles at install time 
using only a bootable NixOS image and network connectivity.

Due to the number of different machines I maintain and how often I change their intended purpose I 
find it essential to be able to take a new system from baremetal to a pre-defined, purposefully built 
system serving in it's intended function as effortlessly as possible. NixOS's flakes and profiles 
provide a fantastic platform on which to build this functionality .

### Disclaimer
Any tooling or documentation here comes with absolutely no guarantees or support of any kind. It is 
to be used at your own risk. Any damages, issues, losses or problems caused by the use of any tooling 
or documentation here is strictly the responsiblity of the end user and not the developer/creator of 
this project. This project is highly opinionated and primarily for my own use but your welcome to 
fork it and build on my work.

## Getting started
***clu***, a simple bash script, provides an install wizard to:

* Prompt you for a few simple customization selections
* Automate the annoying tasks like
  * disk paritioning and mounting
  * generation of nixos hardware configuration
  * transfering your customizations to the underlying nix flake
  * installing your complete system via nix flakes

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

3. Boot from the new USB

4. Download the installer
   ```bash
   $ curl -sL -o clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
   ```

5. Execute the installer
   ```bash
   $ chmod +x clu
   $ nix-shell -p git jq
   $ sudo ./clu -f https://github.com/phR0ze/nixos-config
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

2. Modify the `flake.nix` file changing the `nixosConfigurations.iso` block as desired

3. Commit or at the least stage your changes so Nix will see them
   ```bash
   $ git add .
   ```

4. Now build the iso
   ```bash
   $ nix build .#nixosConfigurations.iso.config.system.build.isoImage
   ```

5. The ISO will end up in `result/iso/`

## Backlog

## Sometime
* [ ] Install neovim
* [ ] Fix Bash prompt error
* [ ] clu needs to present profiles for install
* [ ] clu to update `flake.nix` with user selection
* [ ] Build out standard xfce desktop
* [ ] Change the autologin welcome message
* [ ] Change the kernel boot colors 

## Completed
* [ ] Warn user before destructive disk commands are run
* [x] Enabling docs
* [x] Build my own minimal.nix
* [x] Disable IPv6
* [x] Default root password
* [x] Default user and password
* [x] Build installer automation
* [x] Inject clu as bootable ISO launch
* [x] clu to clone config repo
* [x] ISO automatically launchs `clu`
* [x] clu installs the nixos configuration

<!-- 
vim: ts=2:sw=2:sts=2
-->
