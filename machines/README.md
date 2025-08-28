# Machines <img style="margin: 6px 13px 0px 0px" align="left" src="../art/logo_36x36.png" />

Machines are independent system configurations for physical or virtual machines. The machine has its 
own configuration `flake.nix`, `flake.lock`, `configuration.nix`, `hardware-configuration.nix` and 
local sops encrypted secrets `args.enc.json` allowing for complete declarative management of the 
machine. The `nixos-config` repo is setup as a single flake with supporting options, modules and 
profiles that are used to compose the different machines being managed. The flake is then setup 
during installation to manage the specific machine it was installed on. At the top level of the repo 
there are reusable shared flake and flake arguments that can then be overridden at the machine level 
if specific customization is desired. This setup makes it both reusable, composable and customizable 
per machine as needed while still retaining complete versioned declarative behavior.

## Shared setup
The root of the project provides a set of reusable shared flake configuration and arguments that may 
be used to compose and manage a machine or overridden as necessary.

* `args.enc.json` - sops encrypted arguments to be shared by all machines or overridden locally
* `args.nix` - non-private arguments to be shared by all machines or overridden locally
* `configuration.nix` - link to the specific `machines/<machine>/configuration.nix`
* `base.lock` - shared flake lock for all machines or overridden locally
* `base.nix` - shared flake management for all machines or overridden locally
* `flake.lock` - machine specific flake lock or copy of base flake lock if not given
* `flake.nix` - machine specific flake or copy of base flake if not given

## Machine setup
Each machine in `nixos-config/machines/` is composed of:
* `args.enc.json` sops encrypted arguments which override `nixos-config/args.enc.json`
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
The top level `args.nix` and sops encrypted`args.enc.json` along with the local sops encrypted 
`args.enc.json` argument files provide a mechanism for rapidly specifying bulk reusable configuration 
across many machines.

### Configuration
| Argument                | Type  | Default         | Description
| ----------------------- | ----- | --------------- | --------------------------------------
| `hostname`              | str   | `nixos`         | Hostname for the machine
| `id`                    | str   |                 | `dbus-uuidgen` generated Machine ID to use for the system
| `profile`               | str   | `xfce/desktop`  | Pre-defined configurations in path './profiles' selection
| `efi`                   | bool  | `false`         | EFI system boot type set during installation
| `mbr`                   | str   | `nodev`         | MBR system boot device set during installation, e.g. `/dev/sda`
| `arch`                  | str   | `x86_64-linux`  | System architecture to use
| `locale`                | str   | `en_US.UTF-8`   | Locale selection
| `timezone`              | str   | `America/Boise` | Time-zone selection
| `bluetooth`             | bool  | `false`         | Enable or disable bluetooth by default
| `autologin`             | bool  | `false`         | Automatically log the user in or not after boot
| `resolution.x`          | int   | `0`             | Resolution x dimension, e.g. 1920
| `resolution.y`          | int   | `0`             | Resolution y dimension, e.g. 1080
| `type.iso`              | bool  | `false`         | Enable or disable ISO mode
| `type.vm`               | bool  | `false`         | Enable or disable VM mode
| `drives`                | list  | [ ]             | List of drive objects
| `drives[x].uuid`        | str   |                 | Drive identifier used in `hardware-configuration.nix`
| `nix.minVer `           | str   | `25.05`         | Nixpkgs minimum version
| `net.bridge.enable`     | bool  | `false`         | Replace the primary NIC with a virtual network bridge
| `net.bridge.name`       | str   | `br0`           | Name to use for the virtual network bridge
| `net.macvlan.name`      | str   | `host`          | Name to use for the host macvlan on the bridge
| `net.macvlan.ip`        | str   |                 | IP to use for the host macvlan else DHCP will be used
| `net.subnet`            | str   |                 | Default subnet to use for machine e.g. `192.168.1.0/24`
| `net.gateway`           | str   |                 | Default gateway to use for machine e.g. `192.168.1.1`
| `net.dns.primary`       | str   | `1.1.1.1`       | Default primary DNS to use for machine e.g. `1.1.1.1`
| `net.dns.fallback`      | str   | `8.8.8.8`       | Default fallback DNS to use for machine e.g. `8.8.8.8`
| `nics`                  | list  | [ ]             | List of NIC objects
| `nics[x].name`          | str   |                 | NIC well known tag e.g. primary
| `nics[x].id`            | str   |                 | NIC system identifier e.g. ens18 
| `nics[x].ip`            | str   |                 | IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
| `nics[x].subnet`        | str   |                 | Subnet to use for this NIC e.g. `192.168.1.0/24`
| `nics[x].gateway`       | str   |                 | Gateway to use for this NIC e.g. `192.168.1.1`
| `nics[x].dns.primary`   | str   |                 | Primary DNS to use for this NIC e.g. `1.1.1.1`
| `nics[x].dns.fallback`  | str   |                 | Fallback DNS to use for this NIC e.g. `8.8.8.8`
| `user.name`             | str   | `admin`         | User's user name
| `user.pass`             | str   | `admin`         | User's user name
| `user.fullname`         | str   |                 | User's fullname 
| `user.email`            | str   |                 | User's email address
| `git.user`              | str   |                 | Git user name to use as global configuration
| `git.email`             | str   |                 | Git email to use as global configuration
| `git.comment`           | str   |                 | Commit message for simple version tracking

### Services Configuration
| Argument                | Type  | Default         | Description
| ----------------------- | ----- | --------------- | --------------------------------------
| `nix.cache.enable`      | str   |                 | IP of the local Nix Binary Cache
| `nix.cache.ip`          | str   |                 | IP of the local Nix Binary Cache
| `nix.cache.port`        | int   |                 | Port of the local Nix Binary Cache
| `nfs.enable`            | bool  | `false`         | Enable pre-configured nfs shares for this system
| `nfs.entries`           | list  | [ ]             | List of nfs entries
| `smb.enable`            | bool  | `false`         | Enable pre-configured nfs shares for this system
| `smb.user`              | str   |                 | Default SMB user if override not given
| `smb.pass`              | str   |                 | Default SMB pass if override not given
| `smb.domain`            | str   |                 | Default SMB domain/workgroup if override not given
| `smb.entries`           | list  | [ ]             | List of SMB entries
| `smb.e..[x].mountPoint` | str   |                 | Share entry mount point e.g. `/mnt/Media`
| `smb.e..[x].remotePath` | str   |                 | Share remote path e.g. `192.168.1.2:/srv/nfs/Media` 

<!-- 
vim: ts=2:sw=2:sts=2
-->
