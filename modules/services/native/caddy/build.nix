# Build the caddy package locally, outside any host - see README.md.
#
#   nix build -f ./build.nix                                    # option defaults
#   nix build -f ./build.nix --argstr cloudflarePluginTag v0.2.5 --argstr hash ""
#
# Uses the flake's pinned nixpkgs so the hash matches what host builds see, and takes its defaults
# from the `services.native.caddy` options so they aren't repeated here.
#---------------------------------------------------------------------------------------------------
let
  flake = builtins.getFlake (toString ../../../..);
  pkgs = import flake.inputs.nixpkgs { };
  opts = (import ./default.nix { inherit pkgs; inherit (pkgs) lib; config = { }; })
    .options.services.native.caddy;
in
{
  cloudflarePluginTag ? opts.cloudflarePluginTag.default,
  hash ? opts.cloudflarePluginHash.default,
}:
pkgs.callPackage ./package.nix { inherit cloudflarePluginTag hash; }
