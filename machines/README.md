# Machines <img style="margin: 6px 13px 0px 0px" align="left" src="../art/logo_36x36.png" />

Machines are independent system configurations for physical or virtual machines. The machine has its 
own configuration `flake.nix`, `flake.nix`, `configuration.nix`, `hardware-configuration.nix` and 
local arguments `args.nix` and `args.enc.yaml` allowing for complete declarative management of the 
machine. The `nixos-config` repo is setup as a single flake with supporting options, modules and 
profiles that are used to compose the different machines being managed. The flake is then setup 
during installation to manage the specific machine it was installed on. At the top level of the repo 
there are reusable shared flake and flake arguments that can then be overridden at the machine level 
if specific customization is desired. This setup makes it both reusable, composable and customizable 
per machine as needed while still retaining complete versioned declarative behavior.

## Shared setup
The root of the project provides a set of reusable shared flake configuration and arguments that may 
be used to compose and manage a machine or overridden as necessary.

* `args.enc.yaml` - private arguments to be shared by all machines or overridden locally
* `args.nix` - non-private arguments to be shared by all machines or overridden locally
* `configuration.nix` - link to the specific `machines/<machine>/configuration.nix`
* `base.lock` - shared flake lock for all machines or overridden locally
* `base.nix` - shared flake management for all machines or overridden locally
* `flake.lock` - machine specific flake lock or copy of base flake lock
* `flake.nix` - machine specific flake or copy of base flake

## Machine setup
Each machine in `nixos-config/machines/` is composed of:
* `args.enc.yaml` private machine arguments and will override `nixos-config/args.enc.yaml`
* `args.nix` for non-private machine arguments and will override `nixos-config/args.nix`
* `configuration.nix` for the main machine configuration and used to import the arguments 
* `flake.nix` optional local machine flake configuration to use
* `flake.lock` optional local machine flake lock to use

## Flake switch
`clu` will copy the target machine's flake files to the root of the project to control the flake such 
that the machine is the target. This consists of:
* copying the `nixos-config/machines/<machine>/flake.nix` if present to the root else copy the 
  `nixos-config/base.nix` to the root as `flake.nix`
* copying the `nixos-config/machines/<machine>/flake.lock` if present to the root else copy the
  `nixos-config/base.lock` to the root as `flake.lock`
* creating a link in the root to `nixos-config/machines/<machine>/configuration.nix`

## Machine Args
The `args.nix` and `args.enc.yaml` argument files provide an mechanism to keep simple customization 
separate from the actual configuartion to allow for better reuse across my different machines.

### General configuration
| Argument          | Type  | Default         | Description
| ----------------- | ----- | --------------- | --------------------------------------
| `hostname`        | str   | `nixos`         | Hostname for the machine
| `iso_mode`        | bool  | `false`         | Enable or disable ISO mode
| `profile`         | str   | `xfce/desktop`  | Pre-defined configurations in path './profiles' selection
| `efi`             | bool  | `false`         | EFI system boot type set during installation
| `mbr`             | str   | `nodev`         | MBR system boot device set during installation, e.g. `/dev/sda`
| `arch`            | str   | `x86_64-linux`  | System architecture to use
| `locale`          | str   | `en_US.UTF-8`   | Locale selection
| `timezone`        | str   | `America/Boise` | Time-zone selection
| `bluetooth`       | bool  | `false`         | Enable or disable bluetooth by default
| `autologin`       | bool  | `false`         | Automatically log the user in or not after boot
| `resolution_x`    | int   | `0`             | Resolution x dimension, e.g. 1920
| `resolution_y`    | int   | `0`             | Resolution y dimension, e.g. 1080

### Drives configuration
`drives` is a list of drive type each of which has the following properties
| `uuid`            | str   |                 | Drive identifier used in `hardware-configuration.nix`

### Services configuration
| Argument          | Type  | Default         | Description
| ----------------- | ----- | --------------- | --------------------------------------
| `nix_base`        | str   | `24.05`         | Base install version, not sure this matters
| `nix_cache_enable`| str   |                 | IP of the local Nix Binary Cache
| `nix_cache_ip`    | str   |                 | IP of the local Nix Binary Cache
| `nfs_enable`      | bool  | `false`         | Enable pre-configured nfs shares for this system
| `nfs_entries`     | list  | [ ]             | List of nfs entries
| `smb_enable`      | bool  | `false`         | Enable pre-configured nfs shares for this system
| `smb_user`        | str   |                 | Default SMB user if override not given
| `smb_pass`        | str   |                 | Default SMB pass if override not given
| `smb_domain`      | str   |                 | Default SMB domain/workgroup if override not given
| `smb_entries`     | list  | [ ]             | List of SMB entries
| `mountPoint`      | str   |                 | Share entry mount point e.g. `/mnt/Media`
| `remotePath`      | str   |                 | Share remote path e.g. `192.168.1.2:/srv/nfs/Media` 

### User configuration
| Argument          | Type  | Default         | Description
| ----------------- | ----- | --------------- | --------------------------------------
| `user_fullname`   | str   |                 | User's fullname 
| `user_email`      | str   |                 | User's email address
| `user_name`       | str   | `admin`         | User's user name

### Git configuration
| Argument          | Type  | Default         | Description
| ----------------- | ----- | --------------- | --------------------------------------
| `git_user`        | str   |                 | Git user name to use as global configuration
| `git_email`       | str   |                 | Git email to use as global configuration
| `git_comment`     | str   |                 | Commit message for simple version tracking

### Network configuration
| Argument          | Type  | Default         | Description
| ----------------- | ----- | --------------- | --------------------------------------
| `nic0_name`       | str   |                 | First NIC found in hardware-configuration.nix
| `nic0_ip`         | str   |                 | IP address for nic 0 if given else DHCP, e.g. 192.168.1.12/24
| `nic0_subnet`     | str   |                 | Subnet to use for machine e.g. `192.168.1.0/24`
| `nic0_gateway`    | str   |                 | Gateway to use for machine e.g. `192.168.1.1`
| `nic1_name`       | str   |                 | Second NIC found in hardware-configuration.nix
| `nic1_ip`         | str   |                 | IP address for nic 0 if given else DHCP, e.g. 192.168.1.12/24
| `nic1_subnet`     | str   |                 | Subnet to use for machine e.g. `192.168.1.0/24`
| `nic1_gateway`    | str   |                 | Gateway to use for machine e.g. `192.168.1.1`
| `dns_primary`     | str   | `1.1.1.1`       | Primary DNS to use for machine e.g. `1.1.1.1`
| `dns_fallback`    | str   | `8.8.8.8`       | Fallback DNS to use for machine e.g. `8.8.8.8`

<!-- 
vim: ts=2:sw=2:sts=2
-->
