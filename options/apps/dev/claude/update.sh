#!/usr/bin/env nix-shell
#!nix-shell -p curl jq nix nix-prefetch -i bash
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
NEW_HASH=$(nix hash convert --hash-algo sha256 --to sri \
  "$(nix-prefetch-url --type sha256 "${URL}" 2>/dev/null | tail -1)")

sed -i "s|version = \"${CURRENT}\";|version = \"${LATEST}\";|" package.nix
sed -i "s|hash = \".*\";|hash = \"${NEW_HASH}\";|" package.nix

echo ">> Done! Updated to ${LATEST}"
