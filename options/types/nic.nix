# Declares nic options type for reusability
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    name = lib.mkOption {
      description = lib.mdDoc ''
        NIC identifier in the system. For physical interfaces this will be names like 'eth0', 'eno1' 
        or 'enp1s0'. However in the case where this is a macvlan configuration this value is the name 
        of the macvlan e.g. 'host@br0'.
      '';
      type = types.str;
      example = "eth0";
      default = defaults.name or ""; 
    };

    ip = lib.mkOption {
      description = lib.mdDoc "IP and CIDR combination";
      type = types.str;
      example = "192.168.1.41/24";
      default = defaults.ip or "";
    };

    mac = lib.mkOption {
      type = types.str;
      description = lib.mdDoc "MacVLAN MAC address";
      default = "";
    };

    link = lib.mkOption {
      description = lib.mdDoc ''
        NIC link name. Useful for containers and VMs when creating a macvlan on the host bridge 
        e.g.'br0' which would be the link name in this case";
      '';
      type = types.str;
      default = defaults.link or "br0";
    };

    subnet = lib.mkOption {
      description = lib.mdDoc "Network subnet/CIDR";
      type = types.str;
      default = defaults.subnet or "";
    };

    gateway = lib.mkOption {
      description = lib.mdDoc "Network gateway";
      type = types.str;
      default = defaults.gateway or "";
    };

    dns = lib.mkOption {
      description = lib.mdDoc "DNS for the interface";
      type = types.nullOr (types.submodule (import ./dns.nix { inherit lib; defaults = defaults.dns or {}; }));
      default = defaults.dns or null;
    };
  };
}
