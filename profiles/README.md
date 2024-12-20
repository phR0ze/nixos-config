# Profiles
Profiles in this context are being defined as a suite of configurations that compose a desired 
desktop environment that is abstracted from the physical or virtual machine it is deployed on. This 
allows for the reuse of profiles to build out then more customized machines that are based on the 
profile. Profiles can be built to provide any number of specialized desktop, windowing, application, 
or service choices to build a system with a specific purpose e.g. a theater focused system, or a 
server or your daily runner desktop. In combination with the final machine customization you can 
build out a number of fully customizable declarative systems that can be completly rebuilt from on a 
new blank system in a matter of minutes.

Each profile has its own purpose and features called out in the profile nix file.

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
