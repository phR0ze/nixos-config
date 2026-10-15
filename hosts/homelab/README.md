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
* NVIDIA GeForce GTX 1050 (GP107): nvidia

## Performance
Compared to [family11](../family11/README.md) (6-core AMD Ryzen 5 2600X, GTX 1660):
* **CPU, per-core**: family11 wins - Ryzen 5 2600X (Zen+, 2018) PassMark single-thread ~2406 vs
  homelab's Xeon E5-2637 v2 (Ivy Bridge-EP, 2013) ~1923; the newer architecture and higher boost
  clock outweigh homelab's higher base clock
* **CPU, total throughput**: homelab wins on paper - (2) sockets x 4c/8t = 16 threads vs family11's
  12, and homelab's listed PassMark CPU Mark (~12075) is itself close to the 2600X's ~14053 on a
  single socket, so a second populated socket likely puts homelab ahead in heavily parallel,
  thread-count-bound work; but homelab's actual workload (native services + podman containers, no
  VMs) doesn't stress 16 threads, so this edge mostly goes unused
* **GPU**: family11 wins clearly - GTX 1660 (TU116, Turing) G3D Mark ~11691 vs homelab's GTX 1050
  (GP107, Pascal) ~5049, roughly 2.3x; matters for homelab's Jellyfin transcoding and the
  currently-disabled Immich CUDA path in `configuration.nix`
* **RAM**: homelab has far more installed (96 GB vs family11's 16 GB), but actual usage is ~11 GB
  with everything running (Minecraft's JVM heap alone is pinned at 4 GB) - with no VMs in the
  picture, homelab's workload doesn't need anywhere near 96 GB
* **Power draw**: family11 wins by a wide margin - homelab's (2) 130W-TDP Xeons (260W combined) and
  8-DIMM dual-socket board idle well above a single 95W-TDP Ryzen 5 2600X system (dual-socket HP
  workstations are commonly reported around 90-150W idle vs ~50W for a Ryzen 2600X desktop build);
  running 24/7, that gap is the single biggest cost of keeping the Z620 as-is

Net: homelab's dual-socket design and 96 GB only pay off for VM-heavy or highly parallel workloads,
neither of which homelab actually runs today. For its real job (lightweight native services +
containers, Jellyfin/Immich transcoding), family11's hardware wins on per-core speed, GPU, and
power draw, and loses nothing that's actually used.

## Upgrade notes
**Plan**: rebuild homelab on family11-equivalent hardware (MSI A320M PRO-M2 V2, Ryzen 5 2600X,
GTX 1660) with 32 GB RAM (2x16 GB) instead of family11's 16 GB
* Driven by three things: wanting GPU acceleration for Jellyfin/Immich, the Z620's proprietary PSU
  lacking the PCIe power connectors a GTX 1660 needs, and the idle power savings above
* 32 GB covers homelab's real usage (~11 GB today, Minecraft's JVM heap pinned at 4 GB) with ample
  headroom, assuming no VMs are added later - if that assumption changes, revisit RAM before buying
* A320M PRO-M2 V2 has 4 DIMM slots (vs the 2-slot board in workstation7), so there's room to go to
  64 GB later without a board swap if the workload grows
* Swap `devices.gpu.nvidia` stays as-is in `configuration.nix` - no `devices.gpu.amd` change needed
  since the GTX 1660 is NVIDIA, unlike the AMD upgrade paths suggested for family11/workstation7
