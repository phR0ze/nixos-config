# nixos-config
A simpler approach to deploying pre-defined machines or profiles at install time using only a 
bootable NixOS image and network connectivity.

Due to the number of different machines I maintain and how often I change their intended purpose I 
find it essential to be able to take a new system from baremetal to a pre-defined, purposefully built 
system serving in it's intended function as effortlessly as possible in a repoducible way. NixOS's 
functional Nix expression language and flakes provide a fantastic platform on which to build this 
functionality.

### Disclaimer
Any tooling or documentation here comes with absolutely no guarantees or support of any kind. It is 
to be used at your own risk. Any damages, issues, losses or problems caused by the use of any tooling 
or documentation here is strictly the responsiblity of the end user and not the developer/creator of 
this project. This project is highly opinionated and primarily for personal use but your welcome to 
fork it and build on my work.

### Quick links
* [Getting Started](#getting-started)
  * [Install from upstream ISO](#install-from-upstream-iso)
  * [Install from custom ISO](#install-from-custom-iso)
* [Update and Upgrade](#update-and-upgrade)
  * [Update configuration](#update-configuration)
  * [Upgrade unstable](#upgrade-unstable)
  * [Upgrade pseudo stable](#upgrade-pseudo-stable)
  * [Use unstable for app](#use-unstable-for-app)
* [Advanced use cases](#advanced-use-cases)
  * [Build and deploy production VMs](#build-and-run-test-vm)
  * [Build and run test VM](#build-and-run-test-vm)
  * [Build the live ISO for installation](#build-the-live-iso-for-installation)
* [Development](#development)
  * [Agenix](#agenix)
  * [Clone nixpkgs locally](#clone-nixpkgs-locally)
* [Homelab research](#homelab-research)
* [Backlog](#backlog)
  * [Next](#next)
  * [Sometime](#sometime)
* [Completed](#completed)

## Getting started
***clu*** is a bash script providing:

* An install wizard to walk you through simple system customization
* Automation for annoying tasks like
  * disk paritioning and mounting
  * generation of nixos hardware configuration
  * transferring install time customizations to the underlying nix flake
  * triggering the install of the complete system via nix flakes
* Wrapping of many of the disparate NixOS tooling
  * Provides a single script with documentation on common tasks

### Install from upstream ISO
My configuration can be installed using the pre-built upstream NixOS ISOs

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

### Install from custom ISO
By following the [Build the live ISO for installation](#build-the-live-iso-for-installation) section 
of this doc you can build a custom ISO which will pre-populate the nix store of the target system 
during install with prebuilt binaries (i.e. you can think of it as a local binary cache) which will 
speed up the installation tremendously as you don't need to download nearly as much and any custom 
built binaries will already be built.

Of course this is really only useful if you install a lot of systems or your target system is rather 
limited in resources while your build system is beefy.

1. [Build the live ISO for installation](#build-the-live-iso-for-installation)
2. Burn the ISO to USB see step 2 of [Install from upstream ISO](#install-from-upstream-iso)
3. Boot from the new USB and open a shell
4. You'll be greeted with the clu installer

## Update and Upgrade
I'm defining `update` as configuration changes while an `upgrade` would be changing the versions of 
specific apps or the full system including all apps. I'm also using a two unstable commit strategy to 
make a two versions of the unstable branch available to my system at a time which I name `nixpkgs` 
and `nixpkgs-unstable` which is a bit of a misnomer as they are both based on the unstable branch but 
the different points in time. The one I call `nixpkgs-unstable` is just newer.

  * [Upgrade unstable](#upgrade-unstable)
  * [Upgrade stable](#upgrade-stable)
  * [Use unstable for app](#use-unstable-for-app)

### Update configuration
1. Switch to the configuration folder
   ```bash
   $ cd /etc/nixos
   ```
2. Make changes as desired
   * e.g. perhaps you want to [Upgrade an app](#upgrade-an-app)
3. Commit or stage your configuration changes so they are visible to nix flakes
   ```bash
   $ git add .
   ```
4. Update your system with the configuration changes
   ```bash
   $ sudo ./clu update system
   ```

  * [Upgrade unstable](#upgrade-unstable)

### Upgrade unstable
Note the `base.nix` is all ready setup to use the latest unstable so all you really need to do is 
update to pick it up as follows.

1. Update the lock file to use latest `nixos-unstable`
   ```bash
   $ ./clu update flake
   ```
2. Update target app overrides to use latest unstable updates
   ```bash
   $ ./clu update system
   ```

### Upgrade pseudo stable
Note the `base.nix` is set to a specific unstable version. You'll need to change it to the next 
version you'd like.

1. Modifying `base.nix` to use your preferred nixpkgs sha e.g.
   ```
   nixpkgs.url = "github:nixos/nixpkgs/3566ab7246670a43abd2ffa913cc62dad9cdf7d5";
   ```
2. Update the lock file to use this new sha version and get the latest for `nixos-unstable`
   ```bash
   $ ./clu update flake
   ```
3. Build the target configuration to validate things are still working
   ```bash
   $ ./clu build $HOSTNAME
   ```
4. Update to changes
   ```bash
   $ ./clu update system
   ```

### Use unstable for app
1. [Upgrade unstable branch as desired](#upgrade-unstable)

2. Modify `base.nix` to ensure that the `overlays` section has an entry for your app e.g. `vscode`:
   ```
   vscode = pkgs-unstable.vscode;`
   ```
3. Update to pickup your application changes
   ```bash
   $ ./clu update system
   ```

## Advanced use cases
Most linux users, especially those coming from Arch Linux, will immediately be interested in how they 
can extend and make this their own. Following best practices across the NixOS community I'm breaking 
down my configuration into modules. This allows for composability for higher level concepts like 
machines and profiles. I'm organizing my modules to follow the nix options for the most part.

### Build and deploy production VMs
1. Define the VM to be built
   1. Create a new `machines/vm-NAME` directory
   2. Create the essential files
      1. `configuration.nix`
      2. `args.enc.json`
      3. `args.nix`
2. Update and test your VM locally by building it
   1. From the root of the project run: `./clu build vm $NAME`
   2. And then to run it: `./clu run vm $NAME`
3. Deploy the VM to the hosts vms directory
   ```bash
   $ ./clu deploy vm prod1
   ```

### Build and run test VM
Build the test VM based on the default system configuration and default `flake_opts.nix`. If your
running the same system already this will only take a min and create the `result` link with an
executable `./result/bin/run-nixos-vm` that will start the VM.

1. Build the VM
   ```bash
   $ ./clu build vm
   ```
2. Run the VM
   ```bash
   $ ./clu run vm
   ```

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

## Development

### Dev environment
1. Clone this repo
   ```bash
   $ git clone https://github.com/phR0ze/nixos-config
   ```
2. Configure git hooks
   ```bash
   $ ./clu init
   ```

### Clone nixpkgs locally
It's nice to have a copy of nixpkgs to reference for options

```bash
$ git clone -b nixos-unstable --depth 1 https://github.com/NixOS/nixpkgs
```

## Homelab research
Homelabs are an essential part of any tech enthusiast's set up. At its simplest, just a LAN with access 
to the internet and a single self-hosted service, Homelabs can also scale to be rather complicated 
with VLANs for specific needs and purpose built routers, dozens of IoT devices, numerous self hosted 
services and VPNs to multi-site and cloud based devices. Regardless of the configuration I would 
assert that the fundamental goals should be the same i.e. make the system, despite or perhaps because 
of its complexity, pre-defined, purposefully built and effortlessly reproducible.

Thus I'm working on supporting containers, declared in nix, as my next phase in building out my 
homelab.

**References**
* [MicroVM.nix](https://astro.github.io/microvm.nix/intro.html)

* Uptime Kuma


## Backlog

### Next
* [ ] Build and run vms

### Sometime
* [ ] Change image mime associatation
* [ ] Turn off firefox's prompting to save passwords
* [ ] gtk file picker doesn't sort directories first
* [ ] Add vim-colorize plugin
* [ ] Change nix flake symbol to blue in vim colorizer plugin
* [ ] Change the kernel boot colors 

**Reference nixos-config**
* [Norber Melzer's nixos-config](https://github.com/NobbZ/nixos-config)
* [Hung Le's nixos-config](https://github.com/ixora-0/dotfiles.nix)
* https://github.com/danth/stylix
* https://github.com/benetis/dotfiles-1/blob/master/nixos-config/machines/desktop/modules/android.nix
* https://github.com/benetis/dotfiles-1/blob/master/nixos-config/machines/desktop/modules/hardened-chromium.nix
* https://github.com/thexyno/nixos-config/blob/main/nixos-modules/hardware/laptop.nix
* https://github.com/jakehamilton/config/blob/main/modules/nixos/desktop/addons/gtk/default.nix
* https://github.com/librephoenix/nixos-config

