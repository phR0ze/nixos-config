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
{ config, lib, pkgs, ... }: with lib.types;
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
    #networking.bridge.enable = true;
    programs.virt-manager.enable = true;
  };
}
