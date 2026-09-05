# PrismLauncher

This directory contains the Nix configuration for
[PrismLauncher](https://prismlauncher.org/), a custom Minecraft launcher.

## Offline Patch

The `patches/<version>/offline.patch` makes it possible to play offline

## Local Testing

To build and test the patched package locally:

```bash
nix build -f ./build.nix
```

The resulting binary will be at `./result/bin/prismlauncher`.
