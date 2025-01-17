# QEMU guest configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  machine = config.machine;
  cfg = config.virtualization.qemu.guest;
in
{
  options = {
    virtualization.qemu.guest = {
      enable = lib.mkEnableOption "Configure the VM's guest OS";
    };
  };

  config = lib.mkMerge [

    # Shared standard nix vm and Micro VM configuration
    (lib.mkIf (machine.type.vm) {
      services.qemuGuest.enable = true;             # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;   # We'll use SPICE instead
    })

    # Shared standard nix vm and Micro VM SPICE configuration
    (lib.mkIf (machine.type.vm && machine.vm.spice) {
      services.spice-vdagentd.enable = true;        # SPICE agent to be run on the guest OS
      services.spice-autorandr.enable = true;       # Automatically adjust resolution of guest to spice client size
      services.spice-webdavd.enable = true;         # Enable file sharing on guest to allow access from host

      # Configure higher performance graphics for for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];
    })
  ];
}
