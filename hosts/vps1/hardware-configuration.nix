{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  fileSystems."/" = {
    device = "/dev/vda2"; fsType = "ext4";
  };
  swapDevices = [
    { device = "/dev/vda3"; }
  ];
}
