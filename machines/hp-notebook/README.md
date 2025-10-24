HP Notebook 15-af123c1 <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Hardware](#hardware)
  * [Bios Access](#bios-access)
* [Troubleshooting](#troubleshooting)
  * [X11 fails to start](#x11-fails-to-start)

## Hardware
* HP Notebook 15-af123cl
  * Product# P1B07UA#ABA
  * CPU: AMD A8-7410 2.2 GHz (4 core)
  * Touchscreen 15.6" 1366x768
  * 5 GB DDR3-SDRAM
  * Samsung SSD 840 Pro
  * AMD Radeon R5 graphics
  * SD, SDHC, SDXC
  * DVD Super Multi
  * Wi-Fi 4 802.11n
  * LAN 100 Mbit/s
  * Bluetooth 4.0
  * Battery 3 cell 2800 mAh

### Bios Access
* Press `F10` at boot
* Disable the TPM in the bios and hide it to avoid odd timeout failures with `/dev/tpmrm0`

## Troubleshooting

### X11 fails to start
Radeon driver failure in logs

Reading the `/var/log/X.0.log` shows the following:

```
[   500.955] (EE) Backtrace:
[   500.955] (EE) 0: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (OsSigHandler+0x29) [0x5b52c9]
[   500.957] (EE) unw_get_proc_name failed: no unwind info found [-10]
[   500.957] (EE) 1: /nix/store/8mc30d49ghc8m5z96yz39srlhg5s9sjj-glibc-2.38-44/lib/libc.so.6 (?+0x0) [0x7f499d93eeb0]
[   500.959] (EE) 2: /run/opengl-driver/lib/dri/radeonsi_dri.so (radeon_bo_is_busy.part.0+0x5d) [0x7f499b5aec5d]
[   500.960] (EE) 3: /run/opengl-driver/lib/dri/radeonsi_dri.so (radeon_bo_can_reclaim_slab+0x49) [0x7f499b5b0cf9]
[   500.962] (EE) 4: /run/opengl-driver/lib/dri/radeonsi_dri.so (pb_slabs_reclaim_locked+0x56) [0x7f499baab1a6]
[   500.964] (EE) 5: /run/opengl-driver/lib/dri/radeonsi_dri.so (pb_slab_alloc_reclaimed+0x159) [0x7f499baab339]
[   500.966] (EE) 6: /run/opengl-driver/lib/dri/radeonsi_dri.so (radeon_winsys_bo_create+0x3da) [0x7f499b5affaa]
[   500.968] (EE) 7: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_alloc_resource+0x51) [0x7f499b6e12c1]
[   500.970] (EE) 8: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_buffer_create+0x68) [0x7f499b6e1688]
[   500.972] (EE) 9: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_aligned_buffer_create+0x53) [0x7f499b6e1e83]
[   500.974] (EE) 10: /run/opengl-driver/lib/dri/radeonsi_dri.so (pre_upload_binary.constprop.0+0x17a) [0x7f499b66179a]
[   500.976] (EE) 11: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_shader_binary_upload+0x2e8) [0x7f499b663b88]
[   500.977] (EE) 12: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_create_shader_variant+0x3b1) [0x7f499b668af1]
[   500.979] (EE) 13: /run/opengl-driver/lib/dri/radeonsi_dri.so (_ZL23si_build_shader_variantP9si_shaderib+0x68) [0x7f499b69a478]
[   500.981] (EE) 14: /run/opengl-driver/lib/dri/radeonsi_dri.so (si_shader_select+0x16a9) [0x7f499b69ecc9]
[   500.983] (EE) 15: /run/opengl-driver/lib/dri/radeonsi_dri.so (_Z17si_update_shadersIL13amd_gfx_level9EL11si_has_tess0EL9si_has_gs0EL10si_has_ngg0EEbP10si_context+0xf9) [0x7f499bbcec79]
[   500.985] (EE) 16: /run/opengl-driver/lib/dri/radeonsi_dri.so (_Z11si_draw_vboIL13amd_gfx_level9EL11si_has_tess0EL9si_has_gs0EL10si_has_ngg0EL22si_has_sh_pairs_packed0EEvP12pipe_contextPK14pipe_draw_infojPK23pipe_draw_indirect_infoPK26pipe_draw_start_count_biasj+0x1103) [0x7f499bbda753]
[   500.987] (EE) 17: /run/opengl-driver/lib/dri/radeonsi_dri.so (tc_call_draw_single+0x53) [0x7f499b464fe3]
[   500.989] (EE) 18: /run/opengl-driver/lib/dri/radeonsi_dri.so (tc_batch_execute+0x1b6) [0x7f499b45e656]
[   500.990] (EE) 19: /run/opengl-driver/lib/dri/radeonsi_dri.so (_tc_sync.isra.0+0x198) [0x7f499b45ed98]
[   500.992] (EE) 20: /run/opengl-driver/lib/dri/radeonsi_dri.so (tc_texture_subdata+0x2a9) [0x7f499b468069]
[   500.994] (EE) 21: /run/opengl-driver/lib/dri/radeonsi_dri.so (st_TexSubImage+0xf5e) [0x7f499af6ae0e]
[   500.995] (EE) 22: /run/opengl-driver/lib/dri/radeonsi_dri.so (st_TexImage+0xa1) [0x7f499af6b901]
[   500.997] (EE) 23: /run/opengl-driver/lib/dri/radeonsi_dri.so (teximage_err+0x851) [0x7f499af42e61]
[   500.999] (EE) 24: /run/opengl-driver/lib/dri/radeonsi_dri.so (_mesa_TexImage2D+0x41) [0x7f499af45191]
[   500.999] (EE) 25: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/lib/xorg/modules/libglamoregl.so (glamor_upload_picture_to_texture+0x2f5) [0x7f499d3064d5]
[   501.000] (EE) 26: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/lib/xorg/modules/libglamoregl.so (glamor_composite_choose_shader.constprop.0+0x7b7) [0x7f499d2f6b57]
[   501.001] (EE) 27: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/lib/xorg/modules/libglamoregl.so (glamor_composite_clipped_region+0x679) [0x7f499d2f83b9]
[   501.002] (EE) 28: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/lib/xorg/modules/libglamoregl.so (glamor_composite+0x3c8) [0x7f499d2f9d98]
[   501.002] (EE) 29: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (damageComposite+0x1c8) [0x522d88]
[   501.003] (EE) 30: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/lib/xorg/modules/libglamoregl.so (glamor_trapezoids+0x29f) [0x7f499d30151f]
[   501.003] (EE) 31: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (ProcRenderTrapezoids+0x142) [0x518f52]
[   501.004] (EE) 32: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (Dispatch+0x374) [0x4457a4]
[   501.004] (EE) 33: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (dix_main+0x376) [0x449886]
[   501.005] (EE) 34: /nix/store/8mc30d49ghc8m5z96yz39srlhg5s9sjj-glibc-2.38-44/lib/libc.so.6 (__libc_start_call_main+0x7e) [0x7f499d9290ce]
[   501.006] (EE) 35: /nix/store/8mc30d49ghc8m5z96yz39srlhg5s9sjj-glibc-2.38-44/lib/libc.so.6 (__libc_start_main+0x89) [0x7f499d929189]
[   501.007] (EE) 36: /nix/store/hf4rbbcdzgl1nbz4nv8hgwjjl7q8flnn-xorg-server-21.1.11/bin/X (_start+0x25) [0x432825]
[   501.007] (EE)
[   501.007] (EE) Segmentation fault at address 0x40
[   501.007] (EE)
Fatal server error:
[   501.007] (EE) Caught signal 11 (Segmentation fault). Server aborting
[   501.007] (EE)
[   501.007] (EE)
Please consult the The X.Org Foundation support
	 at http://wiki.x.org
 for help.
[   501.007] (EE) Please also check the log file at "/var/log/X.0.log" for additional information.
[   501.007] (EE)
[   501.007] (II) AIGLX: Suspending AIGLX clients for VT switch
[   501.010] (EE) Server terminated with error (1). Closing log file.
```
