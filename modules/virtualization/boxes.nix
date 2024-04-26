# Boxes configuration
#
# ### Guest
# - when running NixOS as a guest enable QEMU with `service.qemuGuest.enable = true;`
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

    programs.virt-manager.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];                # default option
      qemu.ovmf.enable = true;                      # support for UEFI
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];    # support for UEFI
      #qemu.swtpm.enable = true;                    # support for windows
    };

    # Configure virt-manager initial connection
    # Home manager settings
#    dconf.settings = {
#      "org/virt-manager/virt-manager/connections" = {
#        autoconnect = ["qemu:///system"];
#        uris = ["qemu:///system"];
#      };
#    };

    environment.systemPackages = with pkgs; [
      gnome.gnome-boxes
    ];

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.settings.username}.extraGroups = [ "libvirtd" "kvm" "qemu-libvirtd" ];
  };
}
