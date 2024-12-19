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

      # Configure UEFI support
      qemu.ovmf.enable = true;
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];

      # Configure windows swtpm
      qemu.swtpm.enable = true;

      #qemu.vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs support
    };

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.username}.extraGroups = [ "libvirtd" "qemu-libvirtd" ];
  };
}
