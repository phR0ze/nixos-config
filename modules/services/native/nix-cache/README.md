# Nix Binary Cache

Serves the local Nix store as a signed binary cache via `harmonia`. Intended for single-user
homelab use — not hardened for public exposure.

Enable the server with `services.native.nix-cache.host.enable = true`.

## Testing the Cache

```bash
# From another machine
curl 192.168.1.3:5000/nix-cache-info

# Verify a signed package
nix-build '<nixpkgs>' -A pkgs.hello
curl 192.168.1.3:5000/<STORE_HASH>.narinfo
```

## Key Management

Keys live in `include/`:

- `public.pem` - plaintext, read at evaluation time by `modules/system/env/nix.nix` to populate
  `nix.settings.trusted-public-keys` on clients. Public by definition, nothing to protect.
- `private.enc.pem` - the signing key, sops-encrypted in **binary** format (the whole file is the
  secret, there's no key lookup). It's handed to nix-weave's `secret.files."nix-cache/secretKey"`,
  so sops-nix decrypts it at activation time straight to `/run/secrets/nix-cache/secretKey` and
  harmonia loads it from there via systemd `LoadCredential`. It never gets staged into git and
  never lands in the Nix store.

To generate and install a new keypair:

```bash
nix-store --generate-binary-cache-key nix-cache private.pem public.pem
sops --encrypt --input-type binary --output-type binary private.pem > include/private.enc.pem
shred -u private.pem
mv public.pem include/public.pem
```

Point `services.native.nix-cache.host.secretKeyFile` elsewhere if the encrypted key should live
outside this directory.

## Client Configuration

Set `services.native.nix-cache.client.enable = true` on machines that should consume this cache.
