# Layers

A layer is a **chainable, reusable set of options** that turns on a coherent group of `modules/*`
features to shape a generic system - no host-specific values. It's how configuration is shared
across the fleet without duplicating it in every host.

Layers follow the same convention as every other module in this repo:

* **Every layer is imported automatically.** `modules/default.nix` imports `../layers`, which fans
  out through each group's `default.nix` to every layer file. So every layer's *options* are
  defined on every host, always.
* **Importing applies nothing.** A layer's configuration sits behind its own
  `layers.<group>.<name>.enable` gate. You only get a layer's config when you activate it.

A host activates what it wants from its own `config` block:

```nix
config = {
  layers.console.server = {
    enable = true;
    harden = true;
    lowMemory = true;
  };
};
```

## Chaining

Layers compose by **setting each other's options**, never by importing each other. A layer that
builds on a lower one enables it and passes shared flags down, so a single toggle on the host
propagates through the whole chain:

```nix
config = lib.mkIf (cfg.enable) {
  layers.console.core = {
    enable = true;
    lowMemory = lib.mkIf cfg.lowMemory true;
  };
};
```

`console/desktop.nix` -> `console/server.nix` -> `console/core.nix` is the working example: enabling
`desktop` with `harden = true` brings up `server` and `core` with hardening carried along.

Always pass a flag along as `lib.mkIf cfg.flag true`, never as a bare `cfg.flag`. A literal `false`
is a real value that conflicts with another activated layer that wanted the flag on; with `mkIf`, a
chain can only ever add.

## Anatomy

```nix
{ config, lib, pkgs, ... }:
let cfg = config.layers.<group>.<name>;
in {
  options.layers.<group>.<name> = {
    enable = lib.mkEnableOption "Enable the <name> layer";
    harden = lib.mkEnableOption "Enable security hardening configuration";
  };

  config = lib.mkMerge [

    # Base configuration: feature enables, packages, chained layer enables
    (lib.mkIf (cfg.enable) { })

    # One block per optional variant
    (lib.mkIf (cfg.enable && cfg.harden) { })
  ];
}
```

Flags keep the layer count low: a hardened server is `server` with `harden = true`, not a separate
`server-hardened` layer. Reach for a new flag on an existing layer before adding a new layer.

Each layer's purpose, dependencies and features are called out in its own nix file header.

## Adding a layer

1. Create `layers/<group>/<name>.nix` with the anatomy above.
2. Add it to `layers/<group>/default.nix`'s `imports` list (for a new group, create that
   `default.nix` and add the directory to `layers/default.nix`).

That's registration only - it makes the options available fleet-wide. Nothing is applied until a
host or another layer sets `enable`.

## Migration status

`console/` follows this model. `xfce/`, `plasma/`, `budgie/` and `bundles/` are still the old
import-and-apply style: bare `config` bodies with no `enable` gate, aggregated by a `bundles/`
module that the host `imports` directly. Those get converted to `layers.<group>.<name>` namespaces
as they're touched, and `bundles/` goes away in the process - a bundle is just a layer that enables
other layers.

`iso.nix` stays an import target by design; `flake.nix` imports it directly as the ISO build's
entry point.
