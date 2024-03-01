# CLI profiles

## default.nix
Minimal bootable system that is functionally useful

### default packages
Default package list for 23.11 base

| Package name                | Description                                   | Method  |
| --------------------------- | --------------------------------------------- | ------- |
| `acl-2.3.1`                 | Access control list utilities and libraries   | default |
| `attr-2.5.1`                | Extended attribute support library for ACL    | default |
| `bash-interactive-5.2-p15`  | GNU Bourne-Again Shell                        | default |
| `bash-completion-2.11`      | Bash tab completion                           | `option`|
| `bcache-tools-1.0.7`        | Linux block layer cache utils                 | default |
| `bind-9.18.24`              | Portable implementation of the DNS protocol   | default |
| `bzip2-1.0.8`               | A high-quality data compression program       | default |
| `cdrtools`                  | ISO tools e.g. isoinfo, mkisofs               | `pkgs`  |
| `coreutils-full-9.3`        | Linux utilities e.g cat, cp, df, ln, ls, mv   | default |
| `cpio-2.14`                 | Work with cpio or tar archives                | default |
| `curl-8.4.0`                | Networking data transfor with URLS            | default |
| `dbus-1.14.10`              | Freedesktop.org message bus system            | default |
| `ddrescue`                  | GNU ddrescue, a data recovery tool            | `pkgs`  |
| `dhcpcd-9.4.1`              | Client for Dynamic Host Configuration Protocol| default |
| `diffutils-3.10`            | Patch file utility programs: diff, cmp        | default |
| `dos2unix`                  | Text file format converter                    | `pkgs`  |
| `dosfstools-4.2`            | mkfs.fat, mkfs.vfat, fsck.fat, fsck.vfat      | default |
| `e2fsprogs-1.47.0`          | Utilities for ex2/ex3/ex4 filesystems         | default |
| `efibootmgr-18`             | EFI Boot Manager                              | `option`|
| `efivar`                    | Tools to manipulate EFI variables             | `pkgs`  |
| `findutils-4.9.0`           | Find utils, find, xargs                       | default |
| `fuse-3.16.2`               | Library for filesystems in user space         | default |
| `fwupd`                     | Firmware update tool                          | `pkgs`  |
| `gptfdisk`                  | Disk tools e.g. sgdisk, gdisk, cgdisk         | `pkgs`  |
| `gawk-5.2.2`                | GNU awk                                       | default |
| `git-2.42.0`                | The fast distributed version control system   | `pkgs`  |
| `glibc-2.38-44`             | The GNU C Library                             | default |
| `gnugrep-3.11`              | GNU grep                                      | default |
| `gnused-4.9`                | GNU stream editor                             | default |
| `gnutar-1.35`               | GNU tar                                       | default |
| `gnutls-3.8.3`              | GNU tls                                       | default |
| `grub-2.12-rc1`             | GNU GRand Unified Bootloader                  | `option`|
| `gzip-1.13`                 | GNU zip compression                           | default |
| `inxi`                      | CLI system information tool                   | `pkgs`  |
| `iproute2-6.5.0`            | TCP/IP networking utilities                   | default |
| `iptables-1.8.10`           | IP packet filtering                           | default |
| `iputils-20221126`          | IP utilties e.g. ping                         | deafult |
| `jq`                        | Command line JSON processor, depof: kubectl   | `pkgs`  |
| `kbd-2.6.3`                 | Keyboard tools and keyboard maps              | default |
| `kexec-tools-2.0.26`        | Tools related to the kexec feature            | default |
| `kmod-31`                   | Linux kernel management tools                 | default |
| `less-643`                  | A more advanced file pager than 'more'        | default |
| `libcap-2.69`               | POSIX capabilities library                    | default |
| `libisoburn`                | xorriso ISO creation tools                    | `pkgs`  |
| `libressl-3.8.2`            | More secure fork of OpenSSL                   | default |
| `linux-firmware`            | Provides a collection of hardware drivers     | `pkgs`  |
| `linux-headers-6.5`         | Header files for Linux kernel                 | default |
| `linux-pam-1.5.2`           | Pluggable authentication module for user auth | default |
| `logrotate`                 | Rotates and compresses system logs            | `pkgs`  |
| `lvm2-2.03.22`              | Logical Volumne Managment tooling             | default |
| `man-db-2.11.2`             | A utiltity for reading man pages              | default |
| `mkpasswd-5.5.20`           | Overfeatured frontend to crypt                | default |
| `mtools-4.0.43`             | MS-DOS disk utilties                          | default |
| `nano-7.2`                  | Small, limited text editor                    | default |
| `ncurses-6.4`               | Free emulation of curses                      | default |
| `neovim-0.9.4`              | Vim fork for extensibility and agility        | `option`|
| `net-tools-2.10`            | Network subsystem tools e.g. hostname         | default |
| `nfs-utils`                 | Support programs for Network File Systems     | `pkgs`  |
| `nix-2.18.1`                | Nix package manager                           | default |
| `nix-index`                 | Nix files databse for nixpkgs: nix-locate     | `pkgs`  |
| `nix-bash-completions-0.6.8`|                                               | default |
| `nix-info`                  |                                               | default |
| `nixos-build-vms`           |                                               | default |
| `nixos-configuration-reference-manpage`|                                    | default |
| `nixos-enter`               |                                               | default |
| `nixos-firewall-tool`       |                                               | default |
| `nixos-generate-config`     |                                               | default |
| `nixos-help`                |                                               | default |
| `nixos-install`             |                                               | default |
| `nixos-manual-html`         |                                               | default |
| `nixos-option`              |                                               | default |
| `nixos-rebuild`             |                                               | default |
| `nixos-version`             |                                               | default |
| `openresolv-3.13.2`         |                                               | default |
| `openssh-9.6p1`             |                                               | default |
| `p7zip`                     | File archiver for 7zip format, depof: thunar  | `pkgs`  |
| `patch-2.7.6`               |                                               | default |
| `procps-3.3.17`             | System utilities e.g sysctl, free, pkill, ps  | default |
| `psmisc`                    | Proc filesystem utilities e.g. killall        | `pkgs`  |
| `shadow-4.14.2`             | Auth tooling e.g. passwod, su                 | default |
| `smartmontools`             | Monitoring tools for hard drives              | `pkgs`  |
| `squashfsTools`             | mksquashfs, unsquashfs                        | `pkgs`  |
| `starship-1.17.1`           | Colorful customizable info shell prompt       | `pkgs`  |
| `sudo-1.9.15p2`             | Gives certain users abilit to run as root     | default |
| `systemd-254.6`             | A system and service manager for Linux        | default |
| `testdisk`                  | Checks and undeletes partitions + photorec    | default |
| `texinfo-interactive-7.0.3` | GNU documentation system                      | default |
| `time-1.9`                  | Track system resources used for a program     | default |
| `tmux`                      | Terminal multiplexer                          | `pkgs`  |
| `unrar`                     | Uncompress RAR archives                       | `pkgs`  |
| `unzip`                     | Uncompress Zip archives                       | `pkgs`  |
| `usbutils`                  | Tools for working with USB devices e.g. lsusb | `pkgs`  |
| `util-linux-2.39.2`         | Linux system utilities                        | default |
| `uzip`                      | An extraction utility for zip archives        | `pkgs`  |
| `which-2.21`                | Show the full path of commands                | default |
| `wget`                      | Retrieve files using HTTP, HTTPS, and FTP     | `pkgs`  |
| `xz-5.4.4`                  | Compression successor of LZMA                 | default |
| `yq`                        | Command line YAML/XML/TOML processor          | `pkgs`  |
| `zip`                       | Create zip archives                           | `pkgs`  |
| `zstd-1.5.5`                | Arch Linux default compression                | default |

