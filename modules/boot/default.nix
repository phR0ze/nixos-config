# Configure boot
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./grub.nix
  ];

  # Runtime parameters for the kernel as set by sysctl
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;                        # Minimal amount of swapping without disabling entirely

    "net.ipv4.ip_forward" = 1;                  # Enable ipv4 forwarding for running containers
    "net.ipv6.conf.all.forwarding" = 0;         # Disable ipv6 forwarding

    # These are set by default for x11 but resetting incase I switch to Wayland in the future
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/xserver.nix#L749-L750
    "fs.inotify.max_user_watches" = 524288;     # Increase the number of user file watches to max
    "fs.inotify.max_user_instances" = 524288;   # Increase the number of user instances to max
  };

  # Blacklisted modules
  boot.blacklistedKernelModules = [
    "pcspkr"
   # "nouveau"                                  # Uncomment to disable particular video drivers
   # "nvidia"                                   # Uncomment to disable particular video drivers
  ];

  # Configure default kernel modules
  #boot.initrd.kernelModules = [
  #  "i915"
  #];
}

# vim:set ts=2:sw=2:sts=2
