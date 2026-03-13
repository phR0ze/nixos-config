#!/usr/bin/env nix-shell
#!nix-shell -p cacert curl jq bash --pure -i bash

# Fetch the latest version of opencode from GitHub
version=$(curl -s https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo "Latest OpenCode Version: ${version}"
