## Operating System

This system is running NixOS

## Preferred Tooling
* Use `rg` rather than `grep`

## Development environment

Use `nix develop` to enter the dev shell defined in `flake.nix` of the local project if it exists
before running any `cargo`/`rustc`/`rustfmt`/`clippy`/`rust-analyzer` commands.

## Git commits
* NEVER commit automatically. Always wait for explicit user approval before running `git commit`.
* NEVER include in comments or code user private or secret or PII data

