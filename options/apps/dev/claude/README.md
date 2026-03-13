# Claude Code

This directory contains the Nix configuration for
[Claude Code](https://github.com/anthropics/claude-code), an agentic coding tool by Anthropic.

## Updating

To update Claude Code to the latest version and regenerate the `package-lock.json`, run the helper script from this directory:

```bash
./update.sh
```

Alternatively, you can run the command manually:

```bash
nix-shell -p nix-update nodejs --run "AUTHORIZED=1 nix-update -f ./build.nix claude-code --generate-lockfile"
```


## Local Testing

To build and test the package locally:

```bash
nix build -f ./build.nix
```

The resulting binary will be available at `./result/bin/claude`.

## References

- [Claude Code NixPkgs](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/cl/claude-code/package.nix)
