# Minimal bootable bash configuration
#
# ### Features
# - bootable.nix
# - bash.nix
# - nix core configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./minimal.nix
    ../../system/boot/initrd.nix
    ../../system/shell/bash.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
