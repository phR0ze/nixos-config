# nixos-config
Documenting my use of NixOS in a modular way to build up multipurpose machines.

## Getting started
Machine specific configurations are found in the `machines` subfolder of this repository. They might 
be a good starting place for other types as well as many machines are quite similar.

* `machines/beelink_s12_pro` - Intel 12th Gen N100

### Install instructions
1. Clone this repo into `/etc/nixos`
   ```bash
   $ git clone git@github.com:phR0ze/nixos-config.git
   ```
2. Adjust the `/etc/nixos/configuration.nix` to use the correct machine file
   ```bash
   $ nixos-rebuild switch --flake .
   ```

### Features
I've carefully crafted my NixOS config to be modular with Flakes so that I can build out a couple 
different flavors of systems.

* desktop machine
* media machine
* server machine

<!-- 
vim: ts=2:sw=2:sts=2
-->
