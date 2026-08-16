# Caddy (with caddy-dns/cloudflare)

This directory contains the Nix configuration for [Caddy](https://caddyserver.com/), built from
source with the [`caddy-dns/cloudflare`](https://github.com/caddy-dns/cloudflare) module compiled
in, so it can request real Let's Encrypt certificates via Cloudflare DNS-01 challenges. See
`default.nix` for the `domain` option and the `caddy-cloudflare-token` secret it requires.

Built with `buildGoModule`, so the build is reproducible and fully offline like every other
derivation in this flake — no live `go build`/module-proxy fetch happens inside `nix build`.
`include/` holds the Go module (`main.go`, `go.mod`, `go.sum`) that wires the Cloudflare plugin
into Caddy's standard build.

## Updating

To bump versions:

```bash
cd include
nix shell nixpkgs#go --command go get github.com/caddyserver/caddy/v2@vX.Y.Z
nix shell nixpkgs#go --command go get github.com/caddy-dns/cloudflare@latest
nix shell nixpkgs#go --command go mod tidy
```

Then update `version` in `package.nix` to match, and refresh `vendorHash`: set it to
`pkgs.lib.fakeHash`, run a build (see below), and copy the "got:" hash from the failure into
`package.nix`.

## Local Testing

To build and test the package locally:

```bash
nix build -f ./build.nix
```

The resulting binary will be available at `./result/bin/caddy`. Verify the Cloudflare module made
it in:

```bash
./result/bin/caddy list-modules | grep cloudflare
```

## References

- [Caddy DNS providers](https://caddyserver.com/docs/modules/dns.providers)
- [caddy-dns/cloudflare](https://github.com/caddy-dns/cloudflare)
