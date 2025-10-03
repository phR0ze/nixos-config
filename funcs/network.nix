# Network management functions
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: {

  # Convert an IP address prefix length combination to an object
  # - ip: ip address to convert into a { address; prefixLength } object
  toIP = ip: let
    pieces = lib.splitString "/" ip;
  in {
    address = builtins.elemAt pieces 0;
    prefixLength = lib.toInt (builtins.elemAt pieces 1);
  };

  # Extract the target nic and process defaults
  # - args: is the json input used by the machine and related types
  # - name: the target nic's name
  # - dns: default dns to use if not set
  #-------------------------------------------------------------------------------------------------
  getNic = args: name: dns: let
    target = args.net."${name}" or {};
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
}
