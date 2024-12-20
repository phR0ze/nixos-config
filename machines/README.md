# Machines
Machines are independent system configurations for physical or virtual machines. The machine has its 
own independent configuration but imports the reusable profiles as composable chunks of configuration 
to build out the machines purpose. Each machine has its own `flake.lock` and `flake.nix` allowing 
them to have their own nixpkg version and custom overlays and settings specific to physical or 
virtual machine in question. The local flake then imports the local `configuration.nix` which then 
imports all functions, options, modules and profiles and composes them in a custom way to define 
the machine.

* the root of the repo provides `flake_base.nix` and `flake_base.lock` that can be linked to if no 
  local customizations are needed at the flake level

* machines contain a link to the base flake files if no customizations are needed
  * nix uses the final linked file as the path reference point
  * e.g. `nixos-config/flake.nix` => `nixos-config/machines/homelab/flake.nix` => `nixos-config/flake_base.nix`
    is actually using the root of the repo as the reference point

* machines contain independent `flake.nix` and `flake.lock` files if changes are needed
  * nix uses the final linked file as the path reference so independent `flake.nix` will need to 
  update paths internally to work

This composable configuration allows for complete declarative customization of the machine while 
still allowing for reusability of the underlying modules and profiles.

<!-- 
vim: ts=2:sw=2:sts=2
-->
