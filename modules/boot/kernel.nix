# Configure boot
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # Runtime parameters for the kernel as set by sysctl
  boot.kernel.sysctl = {
    "vm.swappiness" = 1;                        # Minimal amount of swapping without disabling entirely
    "net.ipv4.ip_forward" = 1;                  # Enable ipv4 forwarding for running containers
    "net.ipv6.conf.all.forwarding" = 0;         # Disable ipv6 forwarding

    # These are set by default for x11 but resetting incase I switch to Wayland in the future
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/xserver.nix#L749-L750
    "fs.inotify.max_user_watches" = 524288;     # Increase the number of user file watches to max
    "fs.inotify.max_user_instances" = 524288;   # Increase the number of user instances to max

    # Support for bridge virtual switches
    # [netfilter is currently enabled on bridges by default](https://bugzilla.redhat.com/show_bug.cgi?id=512206#c0).
    # This is unneeded additional overhead that can be confusing when trouble shooting. The libvirt team 
    # recommends disabling it for all bridge devices.
    "net.bridge.bridge-nf-call-arptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-iptables" = 0;
  };

  # Blacklisted modules
  boot.blacklistedKernelModules = [
    "pcspkr"
  ];
}
