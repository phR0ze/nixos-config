# Profiles
Profiles in this context are being defined as top level NixOS modules that pre-define a system for a 
pre-determined purpose. Profiles essentially allow you to custom tailor configuration for your 
specific purpose, i.e. maybe a theater focused system, or a minimal server or your daily runner 
desktop. With profiles you can have a new system up and running in minutes exactly the way you wanted 
it. No more painfully pieceing together your perfect system to have it get bricked or fried and 
having to start all over.

## Pre-defined profiles
These are the pre-defined profiles that can be used in the root `flake.nix` by setting the 
`settings.profile` variable e.g. `profile = "xfce/desktop";`. I've crafted the profiles in such a way 
that most build on a prior one including more packages and configuration for their specific use case.

The desktop environment is such a pervasive choice that I've built out different profiles based on 
different desktop environment selections.

### XFCE based profiles
* [xfce/desktop](xfce/desktop) - heavy full development desktop environment, builds on `netbook`
* [xfce/netbook](xfce/netbook) - medium weight system targeting netbooks, mini-pcs etc.., builds on `lite`
* [xfce/theater](xfce/theater) - lean-back media experience for your TV, builds on `lite`
* [xfce/server](xfce/server) - server XFCE environment, builds on `lite`
* [xfce/lite](xfce/lite) - minimal XFCE environment, build on `shell`

### Standard profiles
The standard profiles don't make opinionated GUI choices like which desktop environment, 
window manager or compositor to use. This makes them reusable as building blocks for other profiles. 

* [shell](shell) - minimal bash system, builds on `core`
* [core](core) - minimal environment meant as a container starter

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
