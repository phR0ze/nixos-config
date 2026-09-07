{
  inputs = {
    # nixos-unstable from 2026.07.05
    nixpkgs.url = "github:nixos/nixpkgs/d407951447dcd00442e97087bf374aad70c04cea";

    # nixos-unstable from 2026.08.09 (bumped for vaultwarden 1.37.1, fixes WASM client crashes)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";

    # Flake inputs can't be conditional on which host so declared here, but only gets used by macbook
    nixos-hardware.url = "github:nixos/nixos-hardware/779c32a00155994c86cde8213a8dd4df139d4355";

    nix-weave.url = "github:phR0ze/nix-weave";
    nix-weave.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    _args = import ./args.nix;
    lib = nixpkgs.lib;

    system = _args.host.arch;

    # Minimal, overlay-free pkgs used only for eval-time JSON/YAML helpers in mergeArgs below -
    # the shared nixpkgs.config/overlays (see ./modules/nixpkgs.nix) don't need to be built for this.
    f = (import nixpkgs { inherit system; }).callPackage ./funcs {};

    # Compose the argument overrides for the given hostname
    # ----------------------------------------------------------------------------------------------
    # Layering (lowest to highest priority): root args.nix -> root args.dec.yaml ->
    # hosts/<hostname>/args.nix -> hosts/<hostname>/args.dec.yaml. `host.hostname` and
    # `host.git.comment` are then always set authoritatively so no per-host file needs to declare
    # them: `host.hostname` is simply the hosts/ directory name being built, and `host.git.comment`
    # comes straight from flake introspection (self.rev), not a value written into a tracked file.
    mergeArgs = hostname: let
      isolated = builtins.pathExists (./hosts + "/${hostname}/.isolated");
      hostArgsFile = ./hosts/${hostname}/args.nix;
      hostDecArgsFile = ./hosts/${hostname}/args.dec.yaml;
      hostArgs = if builtins.pathExists hostArgsFile then (import hostArgsFile) else {};
      hostDecArgs = if builtins.pathExists hostDecArgsFile then f.fromYAML hostDecArgsFile else {};
      baseArgsFile = ./args.dec.yaml;
      baseArgs = if isolated then {} else (if builtins.pathExists baseArgsFile then f.fromYAML baseArgsFile else {});
      rootArgs = if isolated then {} else _args;
    in lib.recursiveUpdate (lib.recursiveUpdate (lib.recursiveUpdate rootArgs baseArgs) (lib.recursiveUpdate hostArgs hostDecArgs)) {
      host.hostname = hostname;
      host.git.comment = self.rev or "dirty";
    };

    # Used by the install/iso outputs, which have no per-host directory to derive from
    _bootstrapArgs = lib.recursiveUpdate _args { host.git.comment = self.rev or "dirty"; };

    hostNames = builtins.attrNames (lib.filterAttrs (n: v: v == "directory") (builtins.readDir ./hosts));

    mkHost = hostname: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs f; args = mergeArgs hostname; };
      modules = [ ./modules/nixpkgs.nix inputs.nix-weave.nixosModules.default ./modules (./hosts + "/${hostname}/configuration.nix") ];
    };
  in
  {
    # Lazy attrset, evaluating `.#<hostname>` only forces that host's mkHost body - other
    # (still-encrypted) hosts' args are never touched.
    # ----------------------------------------------------------------------------------------------
    nixosConfigurations = lib.genAttrs hostNames mkHost // {

      # Generic install host configuration based on a generic layer bundle, used to bootstrap a
      # brand new host before it has its own hosts/<hostname> directory.
      # --------------------------------------------------------------------------------------------
      install = lib.nixosSystem {
        inherit system; specialArgs = { inherit inputs f; args = _bootstrapArgs; };
        modules = [ ./modules/nixpkgs.nix ./hardware-configuration.nix (./. + "/" + _args.host.target) ];
      };

      # Defines configuration for building an ISO
      # - specialArgs is being carefully constructed to exclude secrets
      # - re-using layers/iso.nix to set defaults otherwise set in secrets
      # --------------------------------------------------------------------------------------------
      iso = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit f inputs;
          args = lib.recursiveUpdate _bootstrapArgs (import ./layers/iso_args.nix);
        };
        modules = [ ./modules/nixpkgs.nix inputs.nix-weave.nixosModules.default ./modules ./layers/iso.nix ];
      };
    };
  };
}
