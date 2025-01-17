# QEMU host configuration
#
# Sources:
# - nixos/modules/system/build.nix
# - nixos/modules/virtualisation/build-vm.nix
# - nixos/modules/profiles/qemu-guest.nix
# - nixos/modules/virtualisation/qemu-guest-agent.nix
# - nixos/lib/qemu-common.nix
# - nixos/modules/virtualisation/qemu-vm.nix
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
