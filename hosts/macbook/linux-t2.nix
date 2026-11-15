# t2linux kernel for the macbook, with a patch set that applies to the current nixpkgs kernel
#
# ## Why this exists
# nixos-hardware's apple-t2 module builds its kernel from a t2linux patch set pinned at rev
# facf1c77, which targets an earlier 6.18 point release than nixpkgs' `linux_6_18` (now 6.18.59).
# Three of those patches no longer apply, so the kernel - and anything built from its source tree,
# e.g. `cpupower` - fails to build:
#   - 2008-i915-4-lane-quirk-for-mbp15-1  (this host's iGPU 4-lane quirk)
#   - 3001-applesmc-convert-static-structures-to-drvdata  (fans/temps, battery charge limiter)
#   - 4001-asahi-trackpad  (trackpad)
#
# t2linux maintains a `6.18` branch for this kernel series which has all three rebased. This module
# rebuilds the patch list from that branch instead, keeping nixos-hardware's kernel config
# (`structuredExtraConfig`) and everything else about its derivation untouched.
#
# ## Why 1001/1002 stay on the pinned rev
# t2linux's newer branches rename the apple-bce driver to t2bce (`CONFIG_T2BCE_CORE`,
# `drivers/staging/t2bce/`). nixos-hardware's module still refers to the old name - it sets
# `boot.initrd.kernelModules = [ "apple-bce" ]` and `APPLE_BCE = module` - so adopting the renamed
# driver needs that module replaced too. Keeping just these two patches at the pinned rev keeps the
# `apple-bce` naming the module expects; they still apply cleanly to 6.18.59. The `6.18` branch's
# `1003-Fix-for-6.18.patch` is skipped for the same reason: it only fixes t2bce.
#
# ## Other deliberate differences from the pinned set
# - `4005-HID-magicmouse-fix-regression...` is dropped: the `6.18` branch folded it into its `4001`,
#   and applying it on top reports "reversed (or previously applied)".
# - Picks up `5002` (touchbar drm suspend/resume) and `9003`/`9006` (brcmfmac fixes for the BCM4364
#   in this machine), which the branch added.
#
# Every patch below was verified to apply cleanly, in order, to a pristine linux-6.18.59 tree.
#
# ## Removing this
# Drop this file and the `boot.kernelPackages` override in configuration.nix once nixos-hardware
# ships a t2 patch set that applies to the nixpkgs kernel - at which point the apple-t2 module's own
# kernel is correct again. Check `apple/t2/pkgs/linux-t2/stable.json` in nixos-hardware for the rev
# it pins and whether it still predates the t2bce rename.
# --------------------------------------------------------------------------------------------------
{ pkgs, nixos-hardware }:
let
  # nixos-hardware's pinned t2linux rev, kept only for the apple-bce patches
  pinnedRev = "facf1c778667c3ef62104949ef64c75ce7e43b0a";

  # t2linux's maintenance branch for the 6.18 kernel series
  kernel618Rev = "d72d75899f6e01104c22992abedd9ae68956cc3b";

  patchSet = [
    { name = "1001-Add-apple-bce-driver.patch"; rev = pinnedRev; hash = "sha256-rrL3oVkYeq5ZslnjCQw4hcEK6knsm6U/wp1XnJmQTSA="; }
    { name = "1002-Put-apple-bce-in-drivers-staging.patch"; rev = pinnedRev; hash = "sha256-deWROYcncl51sOmtvUHM61e5FM1beHbOJVp4iI31LHM="; }
    { name = "2008-i915-4-lane-quirk-for-mbp15-1.patch"; rev = kernel618Rev; hash = "sha256-gTYP7WHV/Qulobdi1nNdYsv1CWgkM8pGvsCFQ+rvhrw="; }
    { name = "2009-apple-gmux-allow-switching-to-igpu-at-probe.patch"; rev = kernel618Rev; hash = "sha256-6i+fh/Ifle0di5/tMOdMm0NMkEmeUb17hYM/g2j2dfI="; }
    { name = "3001-applesmc-convert-static-structures-to-drvdata.patch"; rev = kernel618Rev; hash = "sha256-c/d+c5eKzhbtfUKtLC7AB+6vMXge4ZzPJAUbNENWH7g="; }
    { name = "3002-applesmc-make-io-port-base-addr-dynamic.patch"; rev = kernel618Rev; hash = "sha256-1fnmMP/3WSy2JqjdCvxu8tWoshCPr8eiG6ttYK/N9WA="; }
    { name = "3003-applesmc-switch-to-acpi_device-from-platform.patch"; rev = kernel618Rev; hash = "sha256-3S6BzyoPLoirfyAu4yDyE9aYjUYr/7etmAvN3uKSDLE="; }
    { name = "3004-applesmc-key-interface-wrappers.patch"; rev = kernel618Rev; hash = "sha256-9Bq28WcqiOnef0br6bATOudr1ViSpajQs7fv7o8Tg0I="; }
    { name = "3005-applesmc-basic-mmio-interface-implementation.patch"; rev = kernel618Rev; hash = "sha256-tnpfmZQw9KQNylpLfGZ+X0IVP79AgeDoTVYF6yUhCRI="; }
    { name = "3006-applesmc-fan-support-on-T2-Macs.patch"; rev = kernel618Rev; hash = "sha256-D5IQHE8QFo49mnUawSau7xUsMFkHKayyhnHW4hi+fWE="; }
    { name = "3007-applesmc-Add-iMacPro-to-applesmc_whitelist.patch"; rev = kernel618Rev; hash = "sha256-rLDuyQYzAaWuu/u6nRRVvGdwyfpLvkGPu1OoD8KS0os="; }
    { name = "3008-applesmc-make-applesmc_remove-void.patch"; rev = kernel618Rev; hash = "sha256-j2Rj1PW/bFEYh9IkGkkG9b+G27IAPCInyd828z4WE1s="; }
    { name = "3009-applesmc-battery-charge-limiter.patch"; rev = kernel618Rev; hash = "sha256-skYKmLsJ6O42/wINLccZWoKS0XhVlC1Nfxi1Ekloxns="; }
    { name = "4001-asahi-trackpad.patch"; rev = kernel618Rev; hash = "sha256-2h3TdPsX9HBXx5jkZ2S2GJkjFcdL8vKD1G69iqd9IWg="; }
    { name = "4003-HID-apple-ignore-the-trackpad-on-T2-Macs.patch"; rev = kernel618Rev; hash = "sha256-LLZzcysLTuQrSXWXbdq7AASxfMInQoqpWzRNZAKws9k="; }
    { name = "4004-HID-magicmouse-Add-support-for-trackpads-found-on-T2.patch"; rev = kernel618Rev; hash = "sha256-kUnbtl/54cihscirl9kP0Gsot7bdP0rYKlj6gQ10hk0="; }
    { name = "5001-HID-appletb-kbd-add-option-to-switch-default-layer-o.patch"; rev = kernel618Rev; hash = "sha256-KV5DTjALzNugs92Jum6VUt0wgblK/6PG1KorovHcIX0="; }
    { name = "5002-drm-appletbdrm-Add-suspend-and-resume-support.patch"; rev = kernel618Rev; hash = "sha256-NFa5ZpNguUC9ELfphvCrVHEh59tN/ZA9vQl6YD1avbI="; }
    { name = "7001-drm-i915-fbdev-Discard-BIOS-framebuffers-exceeding-h.patch"; rev = kernel618Rev; hash = "sha256-/EKN7JsAxcpAgfJFtPp2NLYaGqQ0kl8wjJEXifSzJpY="; }
    { name = "8001-Add-APFS-driver.patch"; rev = kernel618Rev; hash = "sha256-0cCBHFLK4aOQAOl69I2DqNVIYzBSkK/4HsYQghRkLTk="; }
    { name = "8002-Necessary-modifications-to-build-APFS-with-the-kerne.patch"; rev = kernel618Rev; hash = "sha256-zCTetF2NPhMH2BknPumhPz2sf26X9Lcra7xCA3R2WMY="; }
    { name = "9003-PATCH-wireless-next-v2-wifi-brcmfmac-Improve-D3-substate-entering-timeout-handling.patch"; rev = kernel618Rev; hash = "sha256-mvk8p5hEWN3CL1Ye/i9BcTFA3mcb6jBxOLJhLat1ccg="; }
    { name = "9006-PATCH-wifi-brcmfmac-keep-ARP-and-ND-offload-off-on-the-BCM4364.patch"; rev = kernel618Rev; hash = "sha256-eX5eB0VU9uUE6+cW5A/v3iHbnTy5wO4QTwDwd/ErWuU="; }
  ];

  t2Dir = "${nixos-hardware}/apple/t2/pkgs/linux-t2";

  # fetchpatch would normalize the diff; these are applied verbatim, same as nixos-hardware does
  fetch = p: pkgs.fetchurl {
    inherit (p) name hash;
    url = "https://raw.githubusercontent.com/t2linux/linux-t2-patches/${p.rev}/${p.name}";
  };

  # ## How the patch list is replaced
  # Not via overrideAttrs on the kernel derivation's `patches`, and not via `.override` either:
  #
  # - `buildLinux` derives *two* derivations from `kernelPatches` - the kernel itself and
  #   `linux-config-<version>`, which patches its own copy of the source tree to generate the
  #   .config. overrideAttrs only reaches the former, so the pinned patches stay in the latter and
  #   the build fails in linux-config before the kernel is ever touched.
  # - `.override` on what generic.nix returns doesn't reach the kernel's args either. callPackage
  #   propagates override through generic.nix's curried application, so it lands on *generic.nix's*
  #   args - and generic.nix then *appends* that to its own set (`t2-patches ++ args.kernelPatches`),
  #   leaving the broken patches in place and duplicating the rest.
  #
  # generic.nix ends the arg set it hands to `kernel.override` with `// (args.argsOverride or { })`,
  # merging whatever we pass in `argsOverride` over the top as *kernel* args - so `kernelPatches`
  # there replaces its pinned list outright, for the kernel and linux-config alike. (Its own
  # `argsOverride.extraMeta` is a separate key and survives untouched, so the package meta is
  # unchanged.) Note this drops nixpkgs' default kernelPatches, exactly as nixos-hardware already
  # does.
  kernelPatches = map (p: { inherit (p) name; patch = fetch p; }) patchSet;
in
pkgs.callPackage t2Dir {
  argsOverride = { inherit kernelPatches; };
}
