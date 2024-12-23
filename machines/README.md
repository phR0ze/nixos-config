# Machines
Machines are independent system configurations for physical or virtual machines. The machine has its 
own configuration `flake.nix`, `flake.nix`, `configuration.nix`, `hardward-configuration.nix` and 
local arguments `args.nix` and `args.enc.yaml` allowing for complete declarative management of the 
machine. The `nixos-config` repo is setup as a single flake with supporting options, modules and 
profiles that are used to compose the different machines being managed. The flake is then setup 
during installation to manage the specific machine it was installed to. At the top level of the repo 
there are reusable shared flake and flake arguments that can then be overridden at the machine level 
if specific customization is desired. This setup makes it both reusable, composable and customizable 
per machine as needed.

## Shared setup
The root of the project provides a set of reusable shared flake configuration and arguments that may 
be used to compose and manage a machine or overridden as necessary.

* `flake_args.enc.yaml` for private arguments to be shared by all machines or overridden locally
* `flake_args.nix` for non-private arguments to be shared by all machines or overridden locally
* `flake_base.nix` shared flake management for all machines or overridden locally
* `flake_base.lock` shared flake lock for all machines or overridden locally

**Example**
* `nixos-config/configuration.nix` => `machines/<machine>/configuration.nix`
* `nixos-config/flake_args.enc.yaml`
* `nixos-config/flake_args.nix`
* `nixos-config/flake.lock` => `machines/<machine>/flake.lock`
* `nixos-config/flake.nix` => `machines/<machine>/flake.nix`
* `nixos-config/hardware-configuration.nix` => `machines/<machine>/hardware-configuration.nix`

## Machine setup
Each machine is composed of:
* `args.enc.yaml` for private machine arguments and will override `flake_args.enc.yaml`
* `args.nix` for non-private machine arguments and will override `flake_args.nix`
* `configuration.nix` for the main machine configuration and used to import the arguments 
* `flake.nix` loccal machine flake configuration or simply a link back to `flake_base.nix`
* `flake.lock` local machine flake lock or a link back to `flake_base.lock`

**Example**
* `nixos-config/machines/<machine>/args.enc.yaml`
* `nixos-config/machines/<machine>/args.nix`
* `nixos-config/machines/<machine>/configuration.nix`
* `nixos-config/machines/<machine>/flake.lock` => `../../flake_base.lock`
* `nixos-config/machines/<machine>/flake.nix` => `../../flake_base.nix`
* `nixos-config/machines/<machine>/hardware-configuration.nix`

<!-- 
vim: ts=2:sw=2:sts=2
-->
