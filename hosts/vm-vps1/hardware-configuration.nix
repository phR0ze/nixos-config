# Starting point cloned from hosts/vps1 - both are virtio-disk (vda) qemu guests on MBR/legacy
# boot with no separate /boot partition. Verify/regenerate (nixos-generate-config) once NixOS is
# actually installed onto ../vms/ubuntu-server2/disk.qcow2 - device names matched but partition
# boundaries/UUIDs depend on how that disk gets partitioned during install.
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  fileSystems."/" = { device = "/dev/vda2"; fsType = "ext4"; };
  swapDevices = [ { device = "/dev/vda3"; } ];
}
