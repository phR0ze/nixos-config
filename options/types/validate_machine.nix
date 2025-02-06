{ config, lib, args, f, ... }:
let
  cfg = config.machine;
in
{
  assertions = [
    # Input args
    { assertion = (args.hostname == "nixos"); message = "assert args.hostname: ${args.hostname}"; }
    { assertion = (args.profile == "xfce/desktop"); message = "assert args.profile: ${args.profile}"; }
    { assertion = (args.efi == false); message = "assert args.efi: ${f.boolToStr args.efi}"; }
    { assertion = (args.mbr == "nodev"); message = "assert args.mbr: ${args.mbr}"; }
    { assertion = (args.arch == "x86_64-linux"); message = "assert args.arch: ${args.arch}"; }
    { assertion = (args.locale == "en_US.UTF-8"); message = "assert args.locale: ${args.locale}"; }
    { assertion = (args.timezone == "America/Boise"); message = "assert args.timezone: ${args.timezone}"; }
    { assertion = (args.bluetooth == false); message = "assert args.bluetooth: ${f.boolToStr args.bluetooth}"; }
    { assertion = (args.autologin == false); message = "assert args.autologin: ${f.boolToStr args.autologin}"; }
    { assertion = (args.resolution.x == 0); message = "assert args.resolution.x: ${toString args.resolution.x}"; }
    { assertion = (args.resolution.y == 0); message = "assert args.resolution.y: ${toString args.resolution.y}"; }
    { assertion = (args.nix.minVer == "25.05"); message = "assert machine.nix.minVer: ${args.nix.minVer}"; }

    # General args
    { assertion = (cfg.hostname == "vm-test"); message = "assert machine.hostname: ${cfg.hostname}"; }
    { assertion = (cfg.profile == "xfce/desktop"); message = "assert machine.profile: ${cfg.profile}"; }
    { assertion = (cfg.efi == false); message = "assert machine.efi: ${f.boolToStr cfg.efi}"; }
    { assertion = (cfg.mbr == "nodev"); message = "assert machine.mbr: ${cfg.mbr}"; }
    { assertion = (cfg.arch == "x86_64-linux"); message = "assert machine.arch: ${cfg.arch}"; }
    { assertion = (cfg.locale == "en_US.UTF-8"); message = "assert machine.locale: ${cfg.locale}"; }
    { assertion = (cfg.timezone == "America/Boise"); message = "assert machine.timezone: ${cfg.timezone}"; }
    { assertion = (cfg.bluetooth == false); message = "assert machine.bluetooth: ${f.boolToStr cfg.bluetooth}"; }
    { assertion = (cfg.autologin == true); message = "assert machine.autologin: ${f.boolToStr cfg.autologin}"; }
    { assertion = (cfg.resolution.x == 1920); message = "assert machine.resolution.x: ${toString cfg.resolution.x}"; }
    { assertion = (cfg.resolution.y == 1080); message = "assert machine.resolution.y: ${toString cfg.resolution.y}"; }
    { assertion = (cfg.type.iso == false); message = "assert machine.type.iso: ${f.boolToStr cfg.type.iso}"; }
    { assertion = (cfg.type.vm == true); message = "assert machine.type.vm: ${f.boolToStr cfg.type.vm}"; }
    { assertion = (cfg.nix.minVer == "25.05"); message = "assert machine.nix.minVer: ${cfg.nix.minVer}"; }

#    { assertion = (builtins.length cfg.drives == 3); message = "drives: ${toString (builtins.length cfg.drives)}"; }
#    { assertion = ((builtins.elemAt cfg.drives 0).uuid == ""); message = "drives: ${(builtins.elemAt cfg.drives 0).uuid}"; }
#
#    # User args
#    { assertion = (cfg.user.fullname == "admin"); message = "machine.user.fullname: ${cfg.user.fullname}"; }
#    { assertion = (cfg.user.email == "admin"); message = "machine.user.email: ${cfg.user.email}"; }
#    { assertion = (cfg.user.name == "admin"); message = "machine.user.name: ${cfg.user.name}"; }
#    { assertion = (cfg.user.pass == "admin"); message = "machine.user.pass: ${cfg.user.pass}"; }
#
#    # Git args
#    { assertion = (cfg.git.user == "admin"); message = "machine.git.user: ${cfg.git.user}"; }
#    { assertion = (cfg.git.email == "admin"); message = "machine.git.email: ${cfg.git.email}"; }
    { assertion = (cfg.git.comment == ""); message = "assert machine.git.comment: ${cfg.git.comment}"; }
#
#    # Network args
#    { assertion = (builtins.length cfg.nics.name == ""); message = "machine.nic0.name: ${cfg.nic0.name}"; }
#    { assertion = (cfg.nic0.name == ""); message = "machine.nic0.name: ${cfg.nic0.name}"; }
#    { assertion = (cfg.nic0.subnet == "192.168.1.0/24"); message = "machine.nic0.subnet: ${cfg.nic0.subnet}"; }
#    { assertion = (cfg.nic0.gateway == "192.168.1.1"); message = "machine.nic0.gateway: ${cfg.nic0.gateway}"; }
#    { assertion = (cfg.nic0.ip.full == ""); message = "machine.nic0.ip.full: ${cfg.nic0.ip.full}"; }
#    { assertion = (cfg.nic0.ip.attrs.address == ""); message = "machine.nic0.ip.attrs.address: ${cfg.nic0.ip.attrs.address}"; }
#    { assertion = (cfg.nic0.ip.attrs.prefixLength == 24); message = "machine.nic0.ip.attrs.prefixLength: ${toString cfg.nic0.ip.attrs.prefixLength}"; }
#    { assertion = (cfg.nic0.dns.primary == "1.1.1.1"); message = "machine.nic0.dns.primary: ${cfg.nic0.dns.primary}"; }
#    { assertion = (cfg.nic0.dns.fallback == "8.8.8.8"); message = "machine.nic0.dns.fallback: ${cfg.nic0.dns.fallback}"; }
  ];
}
#| `drives`                | list  | [ ]             | List of drive objects
#| `drives[x].uuid`        | str   |                 | Drive identifier used in `hardware-configuration.nix`
#| `net.primary`           | str   |                 | Primary network interface to use e.g. ens18
#| `net.bridge.enable`     | bool  | `false`         | Replace the primary NIC with a virtual network bridge
#| `net.bridge.name`       | str   | `br0`           | Name to use for the virtual network bridge
#| `net.macvlan.name`      | str   | `host`          | Name to use for the host macvlan on the bridge
#| `net.macvlan.ip`        | str   |                 | IP to use for the host macvlan else DHCP will be used
#| `net.subnet`            | str   |                 | Default subnet to use for machine e.g. `192.168.1.0/24`
#| `net.gateway`           | str   |                 | Default gateway to use for machine e.g. `192.168.1.1`
#| `net.dns.primary`       | str   | `1.1.1.1`       | Default primary DNS to use for machine e.g. `1.1.1.1`
#| `net.dns.fallback`      | str   | `8.8.8.8`       | Default fallback DNS to use for machine e.g. `8.8.8.8`
#| `nics`                  | list  | [ ]             | List of NIC objects
#| `nics[x].name`          | str   |                 | NIC well known tag e.g. primary
#| `nics[x].id`            | str   |                 | NIC system identifier e.g. ens18 
#| `nics[x].ip`            | str   |                 | IP address to use for this NIC else DHCP, e.g. 192.168.1.12/24
#| `nics[x].subnet`        | str   |                 | Subnet to use for this NIC e.g. `192.168.1.0/24`
#| `nics[x].gateway`       | str   |                 | Gateway to use for this NIC e.g. `192.168.1.1`
#| `nics[x].dns.primary`   | str   |                 | Primary DNS to use for this NIC e.g. `1.1.1.1`
#| `nics[x].dns.fallback`  | str   |                 | Fallback DNS to use for this NIC e.g. `8.8.8.8`
#| `user.name`             | str   | `admin`         | User's user name
#| `user.pass`             | str   | `admin`         | User's user name
#| `user.fullname`         | str   |                 | User's fullname 
#| `user.email`            | str   |                 | User's email address
#| `git.user`              | str   |                 | Git user name to use as global configuration
#| `git.email`             | str   |                 | Git email to use as global configuration
#| `git.comment`           | str   |                 | Commit message for simple version tracking
#
#### Services Configuration
#| Argument                | Type  | Default         | Description
#| ----------------------- | ----- | --------------- | --------------------------------------
#| `nix.cache.enable`      | str   |                 | IP of the local Nix Binary Cache
#| `nix.cache.ip`          | str   |                 | IP of the local Nix Binary Cache
#| `nfs.enable`            | bool  | `false`         | Enable pre-configured nfs shares for this system
#| `nfs.entries`           | list  | [ ]             | List of nfs entries
#| `smb.enable`            | bool  | `false`         | Enable pre-configured nfs shares for this system
#| `smb.user`              | str   |                 | Default SMB user if override not given
#| `smb.pass`              | str   |                 | Default SMB pass if override not given
#| `smb.domain`            | str   |                 | Default SMB domain/workgroup if override not given
#| `smb.entries`           | list  | [ ]             | List of SMB entries
#| `smb.e..[x].mountPoint` | str   |                 | Share entry mount point e.g. `/mnt/Media`
#| `smb.e..[x].remotePath` | str   |                 | Share remote path e.g. `192.168.1.2:/srv/nfs/Media` 
