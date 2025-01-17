# QEMU host configuration
#
# Research:
# - system.build.vm 
#
# Sources:
# - nixos/modules/system/build.nix
#   - ?
# - nixos/modules/virtualisation/build-vm.nix
#   - virtualisation.vmVariant
# - nixos/modules/profiles/qemu-guest.nix
#   - sets up kernel and initrd with virtio drivers
# - nixos/modules/virtualisation/qemu-guest-agent.nix
#   - services.qemuGuest.enable
#   - services.qemuGuest.package
# - nixos/lib/qemu-common.nix
#   - shared qemu utility functions
# - nixos/modules/virtualisation/qemu-vm.nix
#   - defines the result/bin/run-${hostname}-vm run script
#   - virtualisation.PROPETY properties
#     - msize memorySize diskSize diskImage bootLoaderDevice bootPartition rootDevice emptyDiskImages 
#     - graphics resolution cores sharedDirectories additionalPaths forwardPorts restrictNetwork 
#     - vlans interfaces writableStore ...
#   - virtualisation.qemu.networkingOptions
#   - virtualisation.qemu.guestAgent.enable
#   - virtualisation.useNixStoreImage is way faster
#   - virtualisation.directBoot to avoid the bootloader
#   - 
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  machine = config.machine;
  cfg = config.virtualization.qemu.host;
in
{
  options = {
    virtualization.qemu.host = {
      enable = lib.mkEnableOption "Install and configure QEMU on the host system";
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enable {
      virtualisation.libvirtd = {
        enable = true;

        # Configure UEFI support
        qemu.ovmf.enable = true;
        qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];

        # Configure windows swtpm
        qemu.swtpm.enable = true;

        qemu.vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs support
      };

      environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];

      # Enables the use of qemu-bridge-helper for `type = "bridge"` interface.
      environment.etc."qemu/bridge.conf".text = lib.mkDefault ''
        allow all
      '';

      # Allow nested virtualization
      boot.extraModprobeConfig = "options kvm_intel nested=1";

      services.spice-webdavd.enable = true;             # File sharing support between Host and Guest
      virtualisation.spiceUSBRedirection.enable = true; # Support USB passthrough to VMs from host

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

      users.users.${machine.user.name}.extraGroups = [ "kvm" "libvirtd" "qemu-libvirtd" ];
    })
  ];
}
