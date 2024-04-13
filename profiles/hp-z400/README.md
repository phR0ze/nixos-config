HP Z400
====================================================================================================

<img align="left" width="48" height="48" src="../../art/logo_256x256.png">
Documenting the steps I went through to deploy <b><i>cyberlinux</i></b> onto the
<a href="https://www.notebookcheck.net/Intel-N100-performance-debut-Beelink-Mini-S12-Pro-mini-PC-review.758950.0.html">Beelink S12 Pro</a> <br> This is now a <b>NixOS</b> based system see my <a href="../../">nixos-config</a>
<br><br>

WIP while I switch over to NixOS

### Quick links
* [Graphics](#graphics)

## Graphics
Notes on how I determined the correct configuration for the video card for this system.

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

   ```
   export LIBVA_DRIVER_NAME=i965
   ```
