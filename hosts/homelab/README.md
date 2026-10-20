# Homelab <img style="margin: 6px 13px 0px 0px" align="left" src="../../art/logo_36x36.png" />

### Quick links
* [.. up dir](../../README.md)
* [Hardware details](#hardware-details)
* [Performance](#performance)
* [Upgrade notes](#upgrade-notes)

## Hardware details
* HP Z620 Workstation (BIOS J61 v03.86, 2015-01-16)
* (2) 4-core Intel Xeon E5-2637 v2 @ 1.2-3.8GHz
* 96 GB RAM
* NVIDIA GeForce GTX 1660 (TU116, Turing): nvidia (open kernel modules)

## Performance
Compared to [family11](../family11/README.md) (6-core AMD Ryzen 5 2600X, GTX 1660):
* **CPU, per-core**: Ryzen 5 2600X (Zen+, 2018) wins with PassMark single-thread ~2406 vs
  Xeon E5-2637 v2 (Ivy Bridge-EP, 2013) ~1923; the newer architecture and higher boost
  clock outweigh E5-2637's higher base clock
* **CPU, total throughput**: Dual Xeon E5-2637 wins on paper - (2) sockets x 4c/8t = 16 threads vs
  Ryzen 5 2600X's 12, and the E5-2637 PassMark CPU Mark (~12075) is itself close to the 2600X's ~14053 on a
  single socket, so a second populated socket likely puts this solution ahead in heavily parallel,
  thread-count-bound work; but homelab's actual workload (native services + podman containers, no
  VMs) doesn't stress 16 threads, so this edge mostly goes unused
* **GPU**: tie - both now run a GTX 1660 (TU116, Turing, G3D Mark ~11691), replacing homelab's
  GTX 1050 (GP107, Pascal, ~5049), roughly a 2.3x uplift; matters for Jellyfin transcoding and
  Immich CUDA (Turing is the minimum for Immich's CUDA ML, see modules/services/native/immich)
* **RAM**: this is what sucks. the MSI A320M PRO-M2 V2 only supports (2) memory slots and I only have
  * 16 GB RAM: (2) 8 GB Kingston HyperX Fury DDR4-2400 CL15 (KHX2400C15/8G)
