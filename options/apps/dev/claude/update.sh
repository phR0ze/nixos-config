#!/usr/bin/env nix-shell
#!nix-shell -p nix-update nodejs prefetch-npm-deps -i bash
set -euo pipefail

# Ensure we're in the script's directory
cd "$(dirname "$0")"

echo ">> Updating Claude Code..."
export AUTHORIZED=1
nix-update -f ./build.nix claude-code --generate-lockfile

echo ">> Updating npmDepsHash..."
NEW_HASH=$(prefetch-npm-deps package-lock.json)
sed -i "s|npmDepsHash = \".*\";|npmDepsHash = \"${NEW_HASH}\";|" package.nix

echo ">> Done!"
