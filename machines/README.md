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

<!-- 
vim: ts=2:sw=2:sts=2
-->
