# Import all functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
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

  # Convert an IP to a gateway
  #-------------------------------------------------------------------------------------------------
  # Usage:
  # let subnet = f.toIP "192.168.1.50/24"; in "192.168.1.1"
  #toSubnet = x:
  #  let
  #    ip = lib.splitString "/" x;
  #  in 
  #    subnet
  #  };

  # Convert an IP to a subnet
  #-------------------------------------------------------------------------------------------------
  # Usage:
  # let subnet = f.toIP "192.168.1.50/24"; in "192.168.1.0/24"
  #toSubnet = x:
  #  let
  #    ip = lib.splitString "/" x;
  #  in 
  #    subnet
  #  };

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

  # Extract the target service and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target service's name used for user name and group
  # - uid: is the specific target service's user id
  # - gid: is the specific target service's group id
  #-------------------------------------------------------------------------------------------------
  getService = args: name: uid: gid:
    let
      # Setup defaults to merge with input args
      defaults = {
        name = name;
        user = {
          name = name;
          group = name;
          uid = uid;
          gid = gid;
        };
      };

      # Find the specific service by name
      filtered = builtins.filter (x: x.name == name) args.services or [];

      # Now extract the service and merge with defaults
      service = if (builtins.length filtered > 0)
        then (builtins.elemAt filtered 0) // defaults
        else ({ nic = {}; port = 80; }) // defaults;
    in service;
}
