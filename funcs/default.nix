# Import all functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
let
  # Bound here rather than only in the attrset below so `getSvcFunc` can call it without making
  # the whole attrset `rec`.
  getSvcValue = path: attrs:
    lib.attrByPath (lib.splitString "." path) null attrs;
in

(import ./network.nix { inherit lib pkgs;}) //
(import ./service.nix { inherit lib pkgs;}) //

# Simple functions
#---------------------------------------------------------------------------------------------------
{
  # Convert a bool into an int
  boolToInt = x: if x then 1 else 0;

  # Convert a bool into a string
  boolToStr = x: if x then "true" else "false";

  # Convert a bool into an integer then to a string
  boolToIntStr = x: if x then "1" else "0";

  # Convert the given json file into nix attribute set
  #-------------------------------------------------------------------------------------------------
  # Usage:
  # local_args = f.fromJSON ./args.dec.json;
  fromJSON = jsonFile:
    builtins.fromJSON (builtins.readFile jsonFile);

  # Convert the given yaml file into nix attribute set
  #-------------------------------------------------------------------------------------------------
  # Usage:
  # local_args = f.fromYAML ./args.dec.yaml;
  fromYAML = yamlFile:
    let
      json = pkgs.runCommand "converted.json" { } ''
        ${lib.getExe pkgs.yj} < ${yamlFile} > $out
      '';
    in builtins.fromJSON (builtins.readFile json);

  # Look up a dot-delimited attribute path within an attribute set, returning `null` if any
  # segment along the way is missing rather than throwing.
  #-------------------------------------------------------------------------------------------------
  # Usage:
  #   f.getSvcValue "native.smb.enable" cfg.services
  inherit getSvcValue;

  # Curried arg reader for a single service namespace: given a `<prefix>` and the args attrset,
  # returns a function that looks a key up under that prefix and yields a definition *only* when
  # the host actually supplied it. An absent arg contributes nothing at all, so the option's own
  # default (or another module's value) still wins instead of a `null` being merged in as a real
  # value. This is the `arg`/`fromArgs` pair every service block in `modules/default.nix` used to
  # spell out by hand.
  #
  # Note this is deliberately not used for a service's `enable`: a host arg of `false` would then
  # be a real definition fighting any other module that wanted the service on. Reach for
  # `getSvcValue` there and gate with `lib.mkIf (... == true) true`.
  #-------------------------------------------------------------------------------------------------
  # Usage:
  #   let arg = f.getSvcFunc "native.smb" cfg.services;
  #   in { services.native.smb = { user = arg "user"; pass = arg "pass"; }; }
  getSvcFunc = prefix: attrs: name:
    let value = getSvcValue "${prefix}.${name}" attrs;
    in lib.mkIf (value != null) value;

  # Provide mkIf support for an else clause
  #-------------------------------------------------------------------------------------------------
  # Usage: 
  #   config.xdg.configFile = (f.mkIfElse cfg.vesktop.enable
  #     { "vesktop/themes".source = catppuccinThemesSrc; }    
  #     { "vencord/themes".source = catppuccinThemesSrc; }    
  #   );
  mkIfElse = p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ];
}
