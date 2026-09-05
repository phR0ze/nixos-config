#!/usr/bin/env nix-shell
#!nix-shell -p nix-update -i bash
set -euo pipefail

# Ensure we're in the script's directory
cd "$(dirname "$0")"

echo ">> Updating Gemini CLI..."
nix-update -f ./build.nix gemini-cli
echo ">> Done!"
