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

  # Extract the target nic and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target nic's name
  # - dns: default dns to use if not set
  #-------------------------------------------------------------------------------------------------
  getNic = args: name: dns:
    let
      # Set defaults properly
      target = args."${name}" or {};
      nic = {
        name = target.name or "";
        ip = target.ip or "";
        link = target.link or "";
        subnet = target.subnet or "";
        gateway = target.gateway or "";
        dns.primary = target.dns.primary or dns.primary;
        dns.fallback = target.dns.fallback or dns.fallback;
      };
    in nic;

  # Extract the target service and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target service's name used for user name and group
  # - uid: is the specific target service's user id
  # - gid: is the specific target service's group id
  #-------------------------------------------------------------------------------------------------
  getService = args: name: uid: gid:
    let
      # Set defaults properly
      target = args.services.cont."${name}" or {};
      service = {
        enable = target.enable or false;
        name = target.name or name;
        tag = if ((target.tag or "") != "") then target.tag else "latest";
        user = {
          name = target.user.name or name;
          group = target.user.group or name;
          uid = target.user.uid or uid;
          gid = target.user.gid or gid;
        };
        port = target.port or 80;
      };
    in service;
}
