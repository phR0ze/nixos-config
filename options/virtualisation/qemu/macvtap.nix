{ config, pkgs, lib, ... }: with lib.types;
let
  host = config.virtualisation.qemu.host;
  guest = config.virtualisation.qemu.guest;

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) guest.interfaces;
  macvtapInterfaces = interfacesByType "macvtap";
in
{
  config = lib.mkMerge [

    # Scripts to startup and shutdown the macvtap interfaces
    (lib.mkIf (macvtapInterfaces != []) {
      virtualisation.qemu.guest.scripts.macvtap-up = ''
        #! ${pkgs.runtimeShell}

        set -eou pipefail
        '' + lib.concatMapStrings ({ id, mac, macvtap, ... }: ''
          if [ -e /sys/class/net/${id} ]; then
            ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
          fi
          ${lib.getExe' pkgs.iproute2 "ip"} link add link '${macvtap.link}' name '${id}' address '${mac}' type macvtap mode '${macvtap.mode}'
          ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' allmulticast on
          if [ -f "/proc/sys/net/ipv6/conf/${id}/disable_ipv6" ]; then
            echo 1 > "/proc/sys/net/ipv6/conf/${id}/disable_ipv6"
          fi
          ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' up
          ${pkgs.coreutils-full}/bin/chown '${host.user}:${host.group}' /dev/tap$(< "/sys/class/net/${id}/ifindex")
        '') macvtapInterfaces;

      virtualisation.qemu.guest.scripts.macvtap-down = ''
        #! ${pkgs.runtimeShell}

        set -eou pipefail
        '' + lib.concatMapStrings ({ id, ... }: ''
          if [ -e /sys/class/net/${id} ]; then
            ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
          fi
        '') macvtapInterfaces;
    })
  ];
}
