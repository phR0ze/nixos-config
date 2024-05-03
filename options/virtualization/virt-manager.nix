# Virt Manager configuration
#
# ### Guest
# - when running NixOS as a guest enable QEMU with `service.qemuGuest.enable = true;`
# 
# ### Details
# libvirt uses a virtual network switch `virbr0` that all the virtual machines "plug in" to.
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

    virtualisation.libvirtd = {
      enable = true;
      allowedBridges = [ "virbr0" ];                # default option
      qemu.ovmf.enable = true;                      # support for UEFI
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];    # support for UEFI
      qemu.swtpm.enable = true;                     # support for windows
    };

    # Enable USB passthrough support for VMs
    virtualisation.spiceUSBRedirection.enable = true;

    # [netfilter is currently enabled on bridges by default](https://bugzilla.redhat.com/show_bug.cgi?id=512206#c0).
    # This is unneeded additional overhead that can be confusing when trouble shooting. The libvirt team 
    # recommends disabling it for all bridge devices.
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-arptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;
      "net.bridge.bridge-nf-call-iptables" = 0;
    };

    # Create the virbr0 network bridge
    #networking = {
      # dhcpcd.denyInterfaces = [ "macvtap0@*" ]; # avoid assigning dhcp address to bridge
      #bridges.virbr0.interfaces = [ "eth0" ];
      #interfaces.virbr0.useDHCP = true;
    #};

    # Configure virt-manager initial connection
    # Home manager settings
#    dconf.settings = {
#      "org/virt-manager/virt-manager/connections" = {
#        autoconnect = ["qemu:///system"];
#        uris = ["qemu:///system"];
#      };
#    };

    environment.systemPackages = with pkgs; [
      virt-viewer                                   # A slimmed down viewer for virtual machines
    ];

    environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];
    users.users.${args.settings.username}.extraGroups = [ "libvirtd" "kvm" "qemu-libvirtd" ];
  };
}
