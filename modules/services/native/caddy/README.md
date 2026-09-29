# Caddy (with caddy-dns/cloudflare)

`package.nix` builds upstream nixpkgs' `caddy` with the
[`caddy-dns/cloudflare`](https://github.com/caddy-dns/cloudflare) plugin compiled in via
`pkgs.caddy.withPlugins`, so it can request real Let's Encrypt certificates via Cloudflare DNS-01
challenges. Caddy's version follows nixpkgs, and the upstream systemd unit (with its hardening,
capabilities and `Type=notify`) is used unchanged.

## Updating

`services.native.caddy.cloudflarePluginHash` covers the plugin-vendored Caddy source, so it has to
be refreshed whenever nixpkgs bumps `caddy` (a `flake.lock` update) or `cloudflarePluginTag` changes.
The build fails loudly until it is:

1. From this directory, build with the (new) tag and an empty hash (no host evaluation or secrets
   needed):
   ```bash
   nix build -f ./build.nix --argstr cloudflarePluginTag v0.2.5 --argstr hash ""
   ```
2. Copy the `got:` hash from the failure into the `cloudflarePluginTag`/`cloudflarePluginHash`
   option defaults in `default.nix` (or set both on a single host to override).

## Local testing

`build.nix` builds the package with the flake's pinned nixpkgs and the option defaults from
`default.nix`, so it matches what a host build produces:

```bash
nix build -f ./build.nix
./result/bin/caddy list-modules | rg cloudflare
```

`withPlugins`' install check also fails the build if the plugin isn't present at the requested tag.

## Build-time validation

`default.nix` adds a `system.checks` derivation that runs `caddy validate` on the generated
Caddyfile, so a broken `tls`/`dns` block fails the build before the host switches.

## References

- [Caddy DNS providers](https://caddyserver.com/docs/modules/dns.providers)
- [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)
- [nixpkgs `caddy.withPlugins`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ca/caddy/plugins.nix)
