# Hardware
These are pre-defined hardware configurations that can be included at install time to assist in 
getting specific hardware up and running with NixOS. They are specific to my hardware for the most 
part and used as selections in the `installSettings.hardware` array but you can easily clone and 
extend what I've done here.

### Using hardware configurations
The hardware selection in the root `flake.nix` is setup as an array. This allows for applying 
multiple different kinds of hardware configurations. For example you may want specific hardware 
configuration for your mini-pc but also include rare custom patched drivers for an old printer.

**Example with multiple hardware configurations**
```
hardware = [
  "beelink-s12-pro"
  "epson-inkjet-printer-escpr2"
]; 
```

### Hardware configurations
Custom hardware configurations that I maintain for my hardware

* [beelink-s12-pro](beelink-s12-pro)

<!-- 
vim: ts=2:sw=2:sts=2
-->
