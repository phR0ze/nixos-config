#!/usr/bin/env nix-shell
#!nix-shell -p cacert nodejs git nix-update nix gnused findutils bash --pure -i bash

# Fetch the latest version of claude-code from npm
version=$(npm view @anthropic-ai/claude-code version)
echo "Latest Claude Code Version: ${version}"
