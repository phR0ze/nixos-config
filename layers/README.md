# Layers
Layers in this context are being defined as atomic, standalone NixOS modules that compose a desired
desktop environment, abstracted from the physical or virtual host they're deployed on. Layers never
import each other - they're mixed and matched by a host (or by a `bundles/` aggregator) via a flat
`imports` list, the way the module system is meant to be used. Layers can be built to provide any
number of specialized desktop, windowing, application, or service choices to build a system with a
specific purpose e.g. a theater focused system, or a server or your daily runner desktop.
`bundles/` holds thin aggregator modules - nothing but an `imports` list of atomic layers - so hosts
in the same class (e.g. "xfce desktop") don't each have to repeat the same handful of layer imports.
In combination with the final host customization you can build out a number of fully customizable
declarative systems that can be completly rebuilt from on a new blank system in a matter of minutes.

Each layer has its own purpose and features called out in the layer's nix file.

## Hardware considerations

### AMD FirePro V4900
The `[AMD/ATI] Turks GL [FirePro V4900]` seems to work fine with the default `radeon` driver. These 
are older cards and don't support HEVC but work well enough for h264 and simple games like minecraft.

* Used in: ***hp-z400*** and ***hp-z420*** workstations

Notes on validating that my default NixOS video card mesa configuration is sufficient

1. The output of `inxi -G`
   ```bash
   Graphics:  Device-1: Advanced Micro Devices [AMD/ATI] Turks GL [FirePro V4900] driver: radeon v: kernel 
              Display: x11 server: X.org 1.21.1.11 driver: loaded: radeon note: n/a (using device driver) 
              resolution: <missing: xdpyinfo> 
              OpenGL: renderer: AMD TURKS (DRM 2.50.0 / 6.6.18 LLVM 16.0.6) v: 4.5 Mesa 24.0.1 
   ```
2. The `vainfo` tool provides the following and matches, so it seems VA-API is supported
   ```bash
   $ vainfo
   ...
   vainfo: VA-API version: 1.20 (libva 2.20.1)
   vainfo: Driver version: Mesa Gallium driver 24.0.1 for AMD TURKS (DRM 2.50.0 / 6.6.18, LLVM 16.0.6)
   vainfo: Supported profile and entrypoints
   ...
   ```
3. Test va-api usage with mpv
   ```bash
   $ mpv --hwdec=vaapi VIDEOFILE
   ```

<!-- 
vim: ts=2:sw=2:sts=2
-->
