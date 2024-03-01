# CLI profiles

## default.nix
Minimal bootable system that is functionally useful

### default packages
Default package list for 23.11 base

| Package name                | Description                                   | State   |
| --------------------------- | --------------------------------------------- | ------- |
| `acl-2.3.1`                 | Access control list utilities and libraries   | default |
| `attr-2.5.1`                | Extended attribute support library for ACL    | default |
| `bash-interactive-5.2-p15`  | GNU Bourne-Again Shell                        | default |
| `bash-completion-2.11`      | Bash tab completion                           | `option`|
| `bcache-tools-1.0.7`        | Linux block layer cache utils                 | default |
| `bind-9.18.24`              | Portable implementation of the DNS protocol   | default |
| `bzip2-1.0.8`               | A high-quality data compression program       | default |
| `coreutils-full-9.3`        | Basic linux utilities liks ls, cp, mv         | default |
| `cpio-2.14`                 | Work with cpio or tar archives                | default |
| `curl-8.4.0`                | Networking data transfor with URLS            | default |
| `dbus-1.14.10`              | Freedesktop.org message bus system            | default |
| `dhcpcd-9.4.1`              | Client for Dynamic Host Configuration Protocol| default |
| `diffutils-3.10`            | Patch file utility programs: diff, cmp        | default |
| `dosfstools-4.2`            | mkfs.fat, mkfs.vfat, fsck.fat, fsck.vfat      | default |
| `e2fsprogs-1.47.0`          | Utilities for ex2/ex3/ex4 filesystems         | default |
| `efibootmgr-18`             | EFI Boot Manager                              | `option`|
| `findutils-4.9.0`           | Find utils, find, xargs                       | default |
| `fuse-3.16.2`               | Library for filesystems in user space         | default |
| `gawk-5.2.2`                | GNU awk                                       | default |
| `getconf-glibc-2.38-44`     |                                   |
| `getent-glibc-2.38-44`      |                                   |
| `git-2.42.0`                | The fast distributed version control system   |
| `glibc-2.38-44`             |                                   |
| `glibc-locales-2.38-44`     |                                   |
| `gnugrep-3.11`              |                                   |
| `gnused-4.9`                | GNU stream editor                             |
| `gnutar-1.35`               |                                   |
| `gnutls-3.8.3`              | Required by systemd-resolved                  |
| `grub-2.12-rc1`             | GNU GRand Unified Bootloader                  |
| `gzip-1.13`                 |                                   |
| `inxi`                      | CLI system information tool                   |
| `iproute2-6.5.0`            |                                   |
| `iptables-1.8.10`           |                                   |
| `iputils-20221126`          |                                   |
| `kbd-2.6.3`                 |                                   |
| `kexec-tools-2.0.26`        |                                   |
| `kmod-31`                   |                                   |
| `less-643`                  |                                   |
| `libcap-2.69`               |                                   |
| `libressl-3.8.2`            |                                   |
| `linux-headers-6.5`         | Header files for Linux kernel                 |
| `linux-pam-1.5.2`           |                                   |
| `logrotate`                 | Rotates and compresses system logs            |
| `lvm2-2.03.22`              |                                   |
| `man-db-2.11.2`             | A utiltity for reading man pages              |
| `mkpasswd-5.5.20`           |                                   |
| `mount.vboxsf`              |                                   |
| `mtools-4.0.43`             |                                   |
| `nano-7.2`                  |                                   |
| `ncurses-6.4`               |                                   |
| `neovim-0.9.4`              |                                   |
| `net-tools-2.10`            |                                   |
| `nix-2.18.1`                |                                   |
| `nix-bash-completions-0.6.8`|                                   |
| `nix-info`                  |                                   |
| `nixos-build-vms`           |                                   |
| `nixos-configuration-reference-manpage`|                        |
| `nixos-enter`               |                                   |
| `nixos-firewall-tool`       |                                   |
| `nixos-generate-config`     |                                   |
| `nixos-help`                |                                   |
| `nixos-install`             |                                   |
| `nixos-manual-html`         |                                   |
| `nixos-option`              |                                   |
| `nixos-rebuild`             |                                   |
| `nixos-version`             |                                   |
| `openresolv-3.13.2`         |                                   |
| `openssh-9.6p1`             |                                   |
| `patch-2.7.6`               |                                   |
| `procps-3.3.17`             |                                   |
| `psmisc`                    | Proc filesystem utilities e.g. killall        |
| `rar`                       | Create RAR archives                           |
| `shadow-4.14.2`             |                                   |
| `smartmontools`             | Monitoring tools for hard drives              |
| `starship-1.17.1`           |                                   |
| `sudo-1.9.15p2`             | Gives certain users abilit to run as root     |
| `systemd-254.6`             |                                   |
| `texinfo-interactive-7.0.3` |                                   |
| `time-1.9`                  |                                   |
| `tmus`                      | Terminal multiplexer                          |
| `unrar`                     | Uncompress RAR archives                       | 
| `usbutils`                  | Tools for working with USB devices e.g. lsusb | 
| `util-linux-2.39.2`         | Linux system utilities                        | 
| `uzip`                      | An extraction utility for zip archives        | 
| `which-2.21`                | Show the full path of commands                |
| `wget`                      | Retrieve files using HTTP, HTTPS, and FTP     |
| `xz-5.4.4`                  | Compression successor of LZMA                 |
| `zip`                       | Create zip archives                           | 
| `zstd-1.5.5`                | Arch Linux default compression                |

