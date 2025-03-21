# Import all functions
#---------------------------------------------------------------------------------------------------
{ pkgs, lib, ... }:
{
  # Simple functions
  #-------------------------------------------------------------------------------------------------
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

  # Convert an IP address prefix length combination to an object
  #-------------------------------------------------------------------------------------------------
  # Usage:
  # let ip = f.toIP "192.168.1.50/24"; in { address = ip.address; }
  toIP = x:
    let
      ip = lib.splitString "/" x;
    in {
      address = builtins.elemAt ip 0;
      prefixLength = lib.toInt (builtins.elemAt ip 1);
    };

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
