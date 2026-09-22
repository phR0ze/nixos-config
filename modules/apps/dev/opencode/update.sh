#!/usr/bin/env nix-shell
#!nix-shell -p cacert curl jq bash --pure -i bash

# Show the latest commit on opencode's default branch, for picking a new `rev` in package.nix.
# See package.nix's header comment for the full update workflow (hashes, patch rebase).
commit=$(curl -s https://api.github.com/repos/anomalyco/opencode/commits/dev | jq -r '.sha')
echo "Latest OpenCode commit (dev): ${commit}"
