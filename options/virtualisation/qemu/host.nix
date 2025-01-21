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
{ config, lib, pkgs, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.qemu.host;
in
{
  options = {
    virtualisation.qemu.host = {
      enable = lib.mkEnableOption "Install and configure QEMU on the host system";

      stateDir = lib.mkOption {
        type = types.path;
        default = "/var/lib/vms";
        description = "Directory that contains the VMs";
      };

      user = lib.mkOption {
        type = types.str;
        description = "User to use for VMs when running as system services";
        default = "vmuser";
      };

      group = lib.mkOption {
        type = types.str;
        description = "Group to use for VMs when running as system services";
        default = "kvm";
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf cfg.enable {
      # Create an activation script to ensure that the VM state directory exists
      system.activationScripts.vm-host = ''
        mkdir -p ${cfg.stateDir}
        chown ${cfg.user}:${cfg.group} ${cfg.stateDir}
        chmod g+w ${cfg.stateDir}
      '';

      # Create user VMs when runnng as system services
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
      };

      # Remove memory constraints for the vm user
      security.pam.loginLimits = [ {
        domain = cfg.user;
        item = "memlock";
        type = "hard";
        value = "infinity";
      } {
        domain = cfg.user;
        item = "memlock";
        type = "soft";
        value = "infinity";
      } ];

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

      # Allow nested virtualisation
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
