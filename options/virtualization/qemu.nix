# Configure the QEMU host and guest
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  machine = config.machine;
  cfg = config.virtualization;
in
{
  options = {
    virtualization.host = {
      enable = lib.mkEnableOption "Install QEMU and configuration to host VMs";
    };
  };

  config = lib.mkMerge [

    # Shared standard nix vm and Micro VM configuration
    (lib.mkIf (machine.type.vm) {
      services.qemuGuest.enable = true;
      services.x11vnc.enable = lib.mkForce false;
    })

    # Shared standard nix vm and Micro VM SPICE configuration
    (lib.mkIf (machine.type.vm && machine.vm.spice) {
      services.spice-vdagentd.enable = true;  # SPICE agent to be run on the guest OS
      services.spice-autorandr.enable = true; # Automatically adjust resolution of guest to spice client size
      services.spice-webdavd.enable = true;   # Enable file sharing on guest to allow access from host

      # Configure higher performance graphics for for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];
    })

    # Virtualization host configuration
    (lib.mkIf cfg.host.enable {
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

      users.users.${machine.user.name}.extraGroups = [ "kvm" "libvirtd" "qemu-libvirtd" ];
    })
  ];
}
