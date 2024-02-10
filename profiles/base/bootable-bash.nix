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
    ../../system/locale.nix
    ../../system/home/users.nix
    ../../system/security/sudo.nix
    ../../system/services/sshd.nix
    ../../system/nix.nix
  ];
}

# vim:set ts=2:sw=2:sts=2
