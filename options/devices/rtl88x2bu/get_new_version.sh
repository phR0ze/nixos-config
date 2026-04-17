#!/usr/bin/env nix-shell
#!nix-shell -p cacert curl jq bash --pure -i bash

# Fetch the latest commit on morrownr/88x2bu-20210702 main branch
result=$(curl -s https://api.github.com/repos/morrownr/88x2bu-20210702/commits/main)
sha=$(echo "$result" | jq -r '.sha')
date=$(echo "$result" | jq -r '.commit.committer.date' | cut -c1-10)
echo "Latest commit: ${sha}"
echo "Date: ${date}"
