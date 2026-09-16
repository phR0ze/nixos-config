{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/E461-A006"; fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/vda2"; fsType = "ext4";
  };
  swapDevices = [
    { device = "/var/swapfile"; size = 2048; priority = 5; }
  ];
}
