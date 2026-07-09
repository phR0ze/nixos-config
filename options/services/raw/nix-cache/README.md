# Nix Binary Cache

Serves the local Nix store as a signed binary cache via `nix-serve`. Intended for single-user
homelab use — not hardened for public exposure.

## Testing the Cache

```bash
# From another machine
curl 192.168.1.3:5000/nix-cache-info

# Verify a signed package
nix-build '<nixpkgs>' -A pkgs.hello
curl 192.168.1.3:5000/<STORE_HASH>.narinfo
```

## Key Management

Keys are stored in `include/var/lib/nix-cache/`. To generate a new keypair:

```bash
nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
```

## Client Configuration

Set `machine.nix.cache.enable = true` on machines that should consume this cache.
