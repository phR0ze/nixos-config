# VM Prod 1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

Building out a VM as a Portainer containerization solution.

### Quick links
* [.. up dir](../../README.md)

## Overview
Storing the VMs at `/var/lib/vms` with a directory per VM.

## Setup

1. Update the flake.lock as needed
   ```bash
   $ ./clu update flake vm-prod1
   ```
2. Build vm
   ```
   $ ./clu build vm prod1
   ```
3. Run vm
   ```
   $ ./clu run vm prod1
   ```

<!-- 
vim: ts=2:sw=2:sts=2
-->
