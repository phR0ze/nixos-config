# QEMU guest macvtap shutdown script
# Not a NixOS module - a plain function returning the shell script that deletes this guest's macvtap
# interfaces. Imported and called from `guest.nix`, which links the result into
# `result/bin/macvtap-down`. Must be run as root after the VM exits, see `scripts-macvtap-up.nix`
# for the setup half.
#
# ### Params:
# - `lib`, `pkgs`:        the usual nixpkgs handles
# - `macvtapInterfaces`:  `guest.interfaces` filtered down to `type = "macvtap"` entries
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, macvtapInterfaces }:
''
  #! ${pkgs.runtimeShell}

  set -eou pipefail
'' + lib.concatMapStrings ({ id, ... }: ''
  if [ -e /sys/class/net/${id} ]; then
    ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
  fi
'') macvtapInterfaces
