# Completed
* [x] xclip solved my nvim copy paste issues
* [x] Visual Studio Extensions
* [x] Remote Desktop
* [x] XFCE profiles
  * [x] Lightdm background follows desktop
  * [x] Fix nerd fonts in shell
  * [x] Autologin options plumbed in
  * [x] Port cyberlinux cli packages over
  * [x] Adding solarized dircolors theme
  * [x] Add starship command prompt for all users
  * [x] Install neovim as default editor and customize
  * [x] Add the flake nixpkgs to the `NIX_PATH`
* [x] Nix `xfce` options
  * [x] Move launcher to top
  * [x] Move app panel to bottom
  * [x] Add desktop settings including background
  * [x] Add keyboard numlock, repeat delay and rate
  * [x] Configure power management display defaults to be always on
* [x] Nix `files` options
  * [x] Implemented `files.user`, `files.any`, `files.root`, `files.all`
  * [x] Support installing arbitrary files and directories
* [x] clu system automation
  * [x] `./clu registry list`
  * [x] `./clu clean store` wrapper for `nixcl="sudo nix-store --optimise -v && sudo nix-collect-garbage -d";`
* [x] ISO and clu installer automation
  * [x] Create ISO with full live GUI environment
  * [x] ISO nix store is used to pre-populate the target system
  * [x] Inject clu into bootable ISO and auto launch it
  * [x] clu to clone nixos-config repo and install it
  * [x] Pass automation and user set options
  * [x] Warn user before destructive disk operations
  * [x] Default root and user passwords and print them out during install

<!-- 
vim: ts=2:sw=2:sts=2
-->
