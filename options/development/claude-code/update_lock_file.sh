#!/usr/bin/env nix-shell
#!nix-shell -p cacert nodejs git nix-update nix gnused findutils bash --pure -i bash

# Set NPM authorization
export AUTHORIZED=1 

# Fetch the latest version of claude-code from npm
original_path="$(pwd)"
version=$(npm view @anthropic-ai/claude-code version)
echo ">> Latest Claude Code Version: ${version}"

# Now download the package and compute the lock file
tmpdir=$(mktemp -d)
echo ">> Created temp dir: ${tmpdir}"
cd "$tmpdir" || exit

echo ">> Downloading the published tarball..."
npm pack @anthropic-ai/claude-code@"$version"

echo ">> Extracting the tarball..."
tar xf ./*"${version}".tgz
cd package || exit

echo ">> Generating package-lock.json..."
npm install --package-lock-only
cp package-lock.json "$original_path"/package-lock.json
