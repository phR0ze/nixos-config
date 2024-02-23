# Minimal bootable bash configuration
#
# ### Features
# - bootable.nix
# - bash.nix
# - nix core configuration
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  imports = [
#    ./minimal.nix
    ../../system/boot/initrd.nix
#    ../../system/shell/bash.nix
#    ../../system/locale.nix
#    ../../system/users.nix
#    ../../system/security/sudo.nix
#    ../../system/services/sshd.nix
#    ../../system/networking.nix
#    ../../system/nix.nix
  ];

  # Set the NixOS version that this was installed with
  config.system.stateVersion = args.systemSettings.stateVersion;
}

# vim:set ts=2:sw=2:sts=2
