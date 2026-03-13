# Gemini CLI

This directory contains the Nix configuration for
[Gemini CLI](https://github.com/google-gemini/gemini-cli).

## Updating

To update Gemini CLI to the latest version and regenerate the `npmDepsHash`, run the helper script
from this directory:

```bash
./update.sh
```

Alternatively, you can run the command manually:

```bash
nix-shell -p nix-update --run "nix-update -f ./build.nix gemini-cli"
```

## Local Testing

To build and test the package locally:

```bash
nix build -f ./build.nix
```

The resulting binary will be available at `./result/bin/gemini`.

## References

- [Gemini CLI NixPkgs](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ge/gemini-cli/package.nix)
