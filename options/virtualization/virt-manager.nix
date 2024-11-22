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
    programs.virt-manager.enable = true;

    # libvirtd enable qemu by default
    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];                # default option
      qemu.ovmf.enable = true;                      # support for UEFI
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];    # support for UEFI
      qemu.swtpm.enable = true;                     # support for windows
    };

    # Enable USB passthrough support for VMs
    virtualisation.spiceUSBRedirection.enable = true;

    environment.systemPackages = with pkgs; [
      virt-viewer                                   # A slimmed down viewer for virtual machines
    ];

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.settings.username}.extraGroups = [ "libvirtd" "kvm" "qemu-libvirtd" ];
  };
}
