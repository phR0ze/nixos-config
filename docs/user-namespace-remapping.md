# User namespace remapping for `services.oci.*`

## Status
Idea only — not yet implemented. Captured from a discussion while adding `services.oci.newt`.

## Problem
Containers under `services.oci.*` run through rootful `podman` (`virtualisation.oci-containers`
executes as root on the host). None of them pass a `--userns` flag, so podman defaults to no
remapping: the UID a container runs as (e.g. `2005` for newt) is the *same* UID on the host. A
container-runtime escape therefore lands as a real, specific host UID rather than something
meaningless.

## Idea
Enable podman user namespace remapping (`--userns=auto`) so the UID inside a container is
translated to an unrelated, unprivileged UID range on the host. Concretely:

1. Give `root` a subuid/subgid range — NixOS only auto-assigns these to `isNormalUser` accounts,
   not root, so it must be declared explicitly:
   ```nix
   users.users.root.subUidRanges = [ { startUid = 100000; count = 65536; } ];
   users.users.root.subGidRanges = [ { startGid = 100000; count = 65536; } ];
   ```
2. Add `"--userns=auto"` to a service's `extraOptions` (e.g. in `options/services/oci/newt.nix`).
   Podman then allocates a private slice of the subuid/subgid range per container and maps the
   container's UID into it, instead of passing the UID through 1:1.

## Where to start
`newt` is the safe pilot: it has no writable host bind mounts (only `/etc/localtime:ro` plus its
own internal tmpfs), so remapping its UID doesn't affect anything else.

## Why not roll it out everywhere yet
`homarr`, `oneup`, and `stirling-pdf` all have `systemd.tmpfiles.rules`-created
`/var/lib/${cfg.name}/appdata` directories owned by a specific host UID (2000/2001/2002
respectively). `--userns=auto` would break write access to those, since the in-container UID no
longer maps to the host UID that owns the directory. Rolling this out to those services would need
one of:
- idmapped bind mounts (`-v host:container:U`, or podman's newer `--mount ...,idmap`), or
- leaving those services on direct UID passthrough and only remapping stateless/no-volume services.

## Open questions to resolve before implementing
- Confirm the podman version in nixpkgs pin (`d407951447dcd00442e97087bf374aad70c04cea`) supports
  `--mount ...,idmap` cleanly, if we want to extend this past newt.
- Decide whether the subuid/subgid range for `root` belongs in `profiles/base.nix` (so every
  podman-using machine gets it) or is opt-in per machine.
- Verify `f.extendContService` / `f.createContNetwork` don't need changes to keep working once a
  container's UID no longer corresponds to a real host user.
