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

    mapNameFromMAC = lib.mkOption {
      description = lib.mdDoc ''
        MAC address to pin this NIC's `name` to via a udev rule, and disable
        `networking.usePredictableInterfaceNames` for. Needed on hosts (e.g. some cloud/VPS
        providers' virtio NICs) where the kernel's predictable name (`enp0s3`, `ens3`, ...) won't
        match a hardcoded `name` like "eth0" used elsewhere in this host's static config -
        pinning by MAC keeps the name deterministic without predictable naming's bus-topology
        dependency. Leave unset (default) on hosts where predictable naming already matches, or
        where the interface name isn't hardcoded anywhere.
      '';
      type = types.str;
      example = "00:11:22:33:44:55";
      default = defaults.mapNameFromMAC or "";
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
