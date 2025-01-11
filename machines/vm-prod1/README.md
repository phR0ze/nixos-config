# VM Prod 1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

Building out a Micro VM as a Portainer containerization solution.

### Quick links
* [.. up dir](../../README.md)

## Overview
MicroVM stores the VMs at `/var/lib/microvms` a directory per MicroVM.

## Setup
1. Create the machine files
2. Ensure the flake.lock is up-to-date
   ```bash
   $ ./clu update flake vm-prod1
   ```
3. Run with
   ```bash
   $ nix run .#nixosConfigurations.my-microvm.config.microvm.declaredRunner
   ```

<!-- 
vim: ts=2:sw=2:sts=2
-->
