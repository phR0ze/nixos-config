# Import all functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:

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
  #   f.getServiceAttr "oci.pangolin.baseDomain" cfg.services
  getServiceAttr = path: attrs:
    lib.attrByPath (lib.splitString "." path) null attrs;

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
