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

### Accepted args.enc.json values
The supported arguments listed below are used throughout my configuration from the specialArgs 
inclusion that I've named `args` throughout my configuration.

| Argument                | Type  | Default           | Description
| ----------------------- | ----- | ----------------- | --------------------------------------
| `hostname`              | str   | `nixos`           | Hostname for the machine
| `id`                    | str   |                   | `dbus-uuidgen` generated Machine ID to use for the system
| `profile`               | str   | `xfce/desktop`    | Pre-defined configurations in path './profiles' selection
| `efi`                   | bool  | `false`           | EFI system boot type set during installation
| `mbr`                   | str   | `nodev`           | MBR system boot device set during installation, e.g. `/dev/sda`
| `arch`                  | str   | `x86_64-linux`    | System architecture to use
| `locale`                | str   | `en_US.UTF-8`     | Locale selection
| `timezone`              | str   | `America/Boise`   | Time-zone selection
| `bluetooth`             | bool  | `false`           | Enable or disable bluetooth by default
| `autologin`             | bool  | `false`           | Automatically log the user in or not after boot
| `resolution.x`          | int   | `0`               | Resolution x dimension, e.g. 1920
| `resolution.y`          | int   | `0`               | Resolution y dimension, e.g. 1080
| `type.bootable`         | bool  | `false`           | Machine requires a bootloader
| `type.vm`               | bool  | `false`           | Machine is a virtual machine
| `type.iso`              | bool  | `false`           | Enable or disable ISO mode
| `type.develop`          | bool  | `false`           | Machine is intended to be used for development
| `type.theater`          | bool  | `false`           | Machine is intended to be used for media
| `drives`                | list  | [ ]               | List of drive objects
| `drives[x].uuid`        | str   |                   | Drive identifier used in `hardware-configuration.nix`
| `nix.cache.enable`      | str   |                   | IP of the local Nix Binary Cache
| `nix.cache.ip`          | str   |                   | IP of the local Nix Binary Cache
| `nix.cache.port`        | int   |                   | Port of the local Nix Binary Cache
| `nix.minVer `           | str   | `25.05`           | Nixpkgs minimum version
| `git.user`              | str   |                   | Git user name to use as global configuration
| `git.email`             | str   |                   | Git email to use as global configuration
| `git.comment`           | str   |                   | Commit message for simple version tracking
| `net.bridge.enable`     | bool  | `false`           | Replace the primary NIC with a virtual network bridge
| `net.bridge.name`       | str   | `br0`             | Name to use for the virtual network bridge
| `net.macvlan.name`      | str   | `host`            | Name to use for the host macvlan on the bridge
| `net.macvlan.ip`        | str   |                   | IP to use for the host macvlan else DHCP will be used
| `net.nic0.name`         | str   |                   | NIC system identifier e.g. ens18, eth0
| `net.nic0.ip`           | str   |                   | IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
| `net.nic0.gateway`      | str   |                   | Default gateway to use for machine e.g. `192.168.1.1`
| `net.nic0.subnet`       | str   |                   | Default subnet to use for machine e.g. `192.168.1.0/24`
| `net.nic0.dns.primary`  | str   | `1.1.1.1`         | Default primary DNS to use for machine e.g. `1.1.1.1`
| `net.nic0.dns.fallback` | str   | `8.8.8.8`         | Default fallback DNS to use for machine e.g. `8.8.8.8`
| `net.nic1.name`         | str   |                   | NIC system identifier e.g. ens18, eth0
| `net.nic1.ip`           | str   |                   | IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
| `net.nic1.gateway`      | str   |                   | Default gateway to use for machine e.g. `192.168.1.1`
| `net.nic1.subnet`       | str   |                   | Default subnet to use for machine e.g. `192.168.1.0/24`
| `net.nic1.dns.primary`  | str   | `1.1.1.1`         | Default primary DNS to use for machine e.g. `1.1.1.1`
| `net.nic1.dns.fallback` | str   | `8.8.8.8`         | Default fallback DNS to use for machine e.g. `8.8.8.8`
| `nfs.enable`            | bool  | `false`           | Enable pre-configured nfs shares for this system
| `nfs.entries`           | list  | [ ]               | List of nfs entries
| `services`              | list  | [ ]               | List of Service objects
| `services[x].name`      | str   |                   | Name of the service e.g. `stirling-pdf`
| `services[x].type`      | enum  | `cont`            | Type of service `cont` or `nspawn`
| `services[x].port`      | int   | `80`              | Port to map
| `services[x].user`      | user  |                   | User setttings for the service
| `smb.enable`            | bool  | `false`           | Enable pre-configured nfs shares for this system
| `smb.user`              | str   |                   | Default SMB user if override not given
| `smb.pass`              | str   |                   | Default SMB pass if override not given
| `smb.domain`            | str   |                   | Default SMB domain/workgroup if override not given
| `smb.entries`           | list  | [ ]               | List of SMB entries
| `smb.e..[x].mountPoint` | str   |                   | Share entry mount point e.g. `/mnt/Media`
| `smb.e..[x].remotePath` | str   |                   | Share remote path e.g. `192.168.1.2:/srv/nfs/Media` 
| `smb.e..[x].user`       | str   |                   | Share specific user
| `smb.e..[x].pass`       | str   |                   | Share specific pass
| `smb.e..[x].domain`     | str   |                   | Share specific domain
| `smb.e..[x].dirMode`    | str   |                   | Share dir mode
| `smb.e..[x].fileMode`   | str   |                   | Share file mode
| `smb.e..[x].writable`   | str   |                   | Share whether its writable or not
| `smb.e..[x].options`    | str   |                   | Share other options
| `user.name`             | str   | `admin`           | User's user name
| `user.pass`             | str   | `admin`           | User's user name
| `user.fullname`         | str   | `admin`           | User's fullname 
| `user.email`            | str   | `""`              | User's email address
| `user.uid`              | str   | `1000`            | User's id
| `user.gid`              | str   | `100`             | User's gid

<!-- 
vim: ts=2:sw=2:sts=2
-->
