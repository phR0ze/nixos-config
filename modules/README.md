# modules
Most modules here declare highly subjective predefined configuration that won't have any effect
until they are enabled and used as part of a layer or host. A smaller set are always-on baseline
modules (no enable flag) directly imported by `layers/console/core.nix`/`layers/console/base.nix`, and a third set
are gated on `host.type.*` capability flags rather than their own enable option - see CLAUDE.md §5
for the full breakdown. All of them are imported recursively at the top level to make them
accessible to all layers and hosts without any importing required.

<!-- 
vim: ts=2:sw=2:sts=2
-->
