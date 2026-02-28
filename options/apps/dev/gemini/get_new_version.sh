#!/usr/bin/env nix-shell
#!nix-shell -p cacert curl jq bash --pure -i bash

# Fetch the latest version of gemini-cli from GitHub
version=$(curl -s https://api.github.com/repos/google-gemini/gemini-cli/releases/latest | jq -r '.tag_name' | sed 's/^v//')
echo "Latest Gemini CLI Version: ${version}"
