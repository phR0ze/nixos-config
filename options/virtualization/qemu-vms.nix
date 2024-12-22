# Configure the host for VM hosting
#
# ### Research
# - nixos-rebuild build-vm is made for testing with limited configuration capabilities i.e. 
#   essentially just build your existing configuration as a vm which is nice but not meant for 
#   declaratively building and hosting your vms.
# - https://github.com/astro/microvm.nix
#   - https://www.youtube.com/watch?v=iGteDsnlCoY
#   - creates systemd units for tap, macvtap, virtiofsd and others
# - qemu introduced the microvm type which removes legacy clutter and is optimized for VirtIO which 
#   now makes it possible to use VMs much like containers only with more isolation and protection
# 
# ### Details
# - microvm was built to allow for keeping configuration and vm settings together
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  cfg = config.virtualization.host;
  machine = config.machine;
in
{
  options = {
    virtualization.host = {
      enable = lib.mkEnableOption "Install QEMU and configuration to host VMs";
    };
  };

  config = lib.mkIf cfg.enable {

    # Generate systemd services for each enabled VM
#    systemd = lib.mkMerge (lib.lists.forEach machine.vms (x:
#      (lib.mkIf x.enable {
#        services."vm-${x.hostname}" = {
#          wantedBy = [ "multi-user.target" ];
#          wants = [ "network-online.target" ];
#          after = [ "network-online.target" ];
#
#          serviceConfig = {
#            Type = "simple";
#            KillSignal = "SIGINT";
#            WorkingDirectory = "/var/lib/vm-${x.hostname}";
#            ExecStart = "/var/lib/vm-${x.hostname}/result/bin/run-${x.hostname}-vm";
#          };
#        };
#      })
#    ));

    # Enables the use of qemu-bridge-helper for `type = "bridge"` interface.
    environment.etc."qemu/bridge.conf".text = lib.mkDefault ''
      allow all
    '';

    # Allow nested virtualization
    boot.extraModprobeConfig = "options kvm_intel nested=1";

    # Configure SPICE guest service and QEMU accelerated graphics
    # - supports SPICE access remoting
    # - supports copy and pasting between host and guest
    services.spice-vdagentd.enable = true;
    services.spice-webdavd.enable = true;         # File sharing support between Host and Guest
    virtualisation.spiceUSBRedirection.enable = true; # USB passthrough for VMs

    # Additional packages
    environment.systemPackages = with pkgs; [

      # SPICE enabled viewer for virtual machines
      # - can be used in conjunction with libvirtd for a QEMU VM console OR
      # - installs remote-viewer which can be used directly for a QEMU VM console without libvirtd
      # - remote-viewer spice://<host>:5900
      virt-viewer

      spice-gtk         # Spicy GTK SPICE client
      spice-protocol    # SPICE support
      win-virtio        # QEMU support for windows
      win-spice         # SPICE support for windows

      # Quickly create and run optimized Windows, macOS and Linux virtual machines
      # - bash scripts wrapping and controlling QEMU
      # quickemu
    ];

    users.users.${machine.user.name}.extraGroups = [ "kvm" ];
  };
}
