# Virt Manager configuration
# https://nixos.wiki/wiki/Virt-manager
#
# ### Guest
# - when running NixOS as a guest enable QEMU with `service.qemuGuest.enable = true;`
# 
# ### Details
# Virt Manager is the standard GUI for libvirt which in turn uses QEMU which in turn uses KVM.
# So the virtualization stack looks like `Virt Manager` => `libvirtd` => `QEMU` => `KVM`.
#
# - libvirt uses a virtual network switch `virbr0` that all the virtual machines "plug in" to.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualization.virt-manager;

in
{
  options = {
    virtualization.virt-manager = {
      enable = lib.mkEnableOption "Install and configure virt-manager";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    networking.bridge.enable = true;
    programs.virt-manager.enable = true;

    # libvirtd enable qemu by default
    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ config.networking.bridge.name ];

      # Configure UEFI support
      qemu.ovmf.enable = true;
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];

      # Configure windows swtpm
      qemu.swtpm.enable = true;

      #qemu.vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs support
    };

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

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.username}.extraGroups = [ "libvirtd" "kvm" "qemu-libvirtd" ];
  };
}
