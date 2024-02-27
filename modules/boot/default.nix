# Configure boot
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./grub.nix
  ];

  # Configure default kernel modules
  #boot.initrd.kernelModules = [ "ext4" ... ];
}

# vim:set ts=2:sw=2:sts=2
