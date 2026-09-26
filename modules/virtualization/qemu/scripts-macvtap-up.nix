# QEMU guest macvtap startup script
# Not a NixOS module - a plain function returning the shell script that creates this guest's macvtap
# interfaces. Imported and called from `guest.nix`, which links the result into
# `result/bin/macvtap-up`. Must be run as root before the run script, see `scripts-macvtap-down.nix`
# for the teardown half.
#
# ### Params:
# - `lib`, `pkgs`:        the usual nixpkgs handles
# - `macvtapInterfaces`:  `guest.interfaces` filtered down to `type = "macvtap"` entries
# - `userSecretPath`:     path to the admin user name secret, only readable at runtime by root
# - `groupSecretPath`:    path to the admin group secret, only readable at runtime by root
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, macvtapInterfaces, userSecretPath, groupSecretPath }:
''
  #! ${pkgs.runtimeShell}

  set -eou pipefail
'' + lib.concatMapStrings ({ id, mac, macvtap, ... }: ''
  if [ -e /sys/class/net/${id} ]; then
    ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
  fi
'' + (if macvtap.link != "" then ''
  link='${macvtap.link}'
'' else ''
  # No link given - auto-detect the host's current default-route interface at VM-start time, so
  # the guest's own Nix config never has to hardcode a specific physical host's NIC name.
  link=$(${lib.getExe' pkgs.iproute2 "ip"} -4 route show default)
  link=''${link#*dev }
  link=''${link%% *}
  if [ -z "$link" ]; then
    echo "Could not auto-detect a default-route interface to attach macvtap ${id} to; set macvtap.link explicitly" >&2
    exit 1
  fi
'') + ''
  ${lib.getExe' pkgs.iproute2 "ip"} link add link "$link" name '${id}' address '${mac}' type macvtap mode '${macvtap.mode}'
  ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' allmulticast on
  if [ -f "/proc/sys/net/ipv6/conf/${id}/disable_ipv6" ]; then
    echo 1 > "/proc/sys/net/ipv6/conf/${id}/disable_ipv6"
  fi
  ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' up
  ${pkgs.coreutils-full}/bin/chown "$(cat ${userSecretPath}):$(cat ${groupSecretPath})" /dev/tap$(< "/sys/class/net/${id}/ifindex")
'') macvtapInterfaces
