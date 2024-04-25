# Boxes configuration
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.virtualisation.boxes;

in
{
  options = {
    virtualisation.boxes = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable the boxes service";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    virtualisation.libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;                      # support for UEFI
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];    # support for UEFI
      #qemu.swtpm.enable = true;                    # support for windows
    };

    environment.systemPackages = with pkgs; [
      gnome.gnome-boxes
      virt-manager
      #virtio-win   # support for windows
    ];

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.settings.username}.extraGroups = [ "libvirtd" "kvm" "qemu-libvirtd" ];
  };
}
