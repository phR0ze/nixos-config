#!/usr/bin/env nix-shell
#!nix-shell -p curl jq nix -i bash
set -euo pipefail

# Ensure we're in the script's directory
cd "$(dirname "$0")"

echo ">> Fetching latest Claude Code version..."
LATEST=$(curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | jq -r '.version')
echo ">> Latest version: ${LATEST}"

CURRENT=$(grep 'version = "' package.nix | head -1 | sed 's/.*version = "\(.*\)";/\1/')
if [ "${LATEST}" = "${CURRENT}" ]; then
  echo ">> Already up to date (${CURRENT})"
  exit 0
fi

echo ">> Updating ${CURRENT} -> ${LATEST}..."

URL="https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${LATEST}.tgz"
echo ">> Fetching hash for ${URL}..."
# package.nix uses fetchzip, which hashes the *unpacked* contents, not the raw
# tarball — so we must prefetch with --unpack to get a matching hash.
NEW_HASH=$(nix store prefetch-file --unpack --hash-type sha256 --json "${URL}" | jq -r '.hash')

sed -i "s|version = \"${CURRENT}\";|version = \"${LATEST}\";|" package.nix
sed -i "s|hash = \".*\";|hash = \"${NEW_HASH}\";|" package.nix

echo ">> Done! Updated to ${LATEST}"
