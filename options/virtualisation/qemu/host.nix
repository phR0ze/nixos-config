# QEMU host configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.qemu.host;

  macvtapInterfaces = builtins.filter (hostname:
    cfg.vms.${hostname}.interface == "macvtap"
  ) (builtins.attrNames cfg.vms);
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

      group = lib.mkOption {
        type = types.str;
        description = "Group to use for VMs when running as system services";
        default = "users";
      };

      vms = lib.mkOption {
        description = "Virtual machines";
        default = {};
        type = with types; attrsOf (submodule ({name, ...}: {
          options = {
            hostname = lib.mkOption {
              type = types.str;
              description = "VM hostname";
              example = "vm-prod1";
              default = name;
            };
            spicePort = lib.mkOption {
              type = types.int;
              description = "SPICE port to open for external access";
              example = 5971;
            };
            interface = lib.mkOption {
              description = lib.mdDoc "Interface type to use";
              type = types.enum [ "user" "macvtap" ];
              default = "user";
            };
            deploy = lib.mkOption {
              description = lib.mdDoc "Deploy the VM if it doesn't exist on the host yet";
              type = types.bool;
              default = false;
            };
            autostart = lib.mkOption {
              description = lib.mdDoc "Start the VM when the host system boots";
              type = types.bool;
              default = false;
            };
          };
        }));
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Create an activation script to ensure that the VM state directory exists
      system.activationScripts.vm-host = ''
        mkdir -p ${cfg.stateDir}
        chown ${cfg.machine.user.name}:${cfg.group} ${cfg.stateDir}
        chmod g+w ${cfg.stateDir}
      '';

      # Remove memory constraints for the vm user
      security.pam.loginLimits = [ {
        domain = cfg.machine.user.name;
        item = "memlock";
        type = "hard";
        value = "infinity";
      } {
        domain = cfg.machine.user.name;
        item = "memlock";
        type = "soft";
        value = "infinity";
      } ];

      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;                   # Configure windows swtpm
        qemu.ovmf.enable = true;                    # Configure UEFI support
        qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];  # Configure UEFI support
        qemu.vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs support
      };

      environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];

      # Enables the use of qemu-bridge-helper for `type = "bridge"` interface.
      environment.etc."qemu/bridge.conf".text = lib.mkDefault ''
        allow all
      '';

      # Allow qemu-bridge-helper to create tap interfaces and attach them to
      # a bridge without being root
#      security.wrappers.qemu-bridge-helper = {
#        source = "${pkgs.qemu-utils}/libexec/qemu-bridge-helper";
#        owner = "root";
#        group = "root";
#        capabilities = "cap_net_admin+ep";
#      };

      # Allow nested virtualisation
      boot.extraModprobeConfig = "options kvm_intel nested=1";

      services.spice-webdavd.enable = true;             # File sharing support between Host and Guest
      virtualisation.spiceUSBRedirection.enable = true; # Support USB passthrough to VMs from host

      # Additional packages
      environment.systemPackages = with pkgs; [
        virt-viewer       # Provides SPICE client `remote-viewer spice:://<host>:5900`
        spice-gtk         # Provides GTK SPICE client `spicy`
        spice-protocol    # SPICE support
        win-virtio        # QEMU support for windows
        win-spice         # SPICE support for windows
        # quickemu        # Create Windows VM easily
      ];

      users.users.${machine.user.name}.extraGroups = [ "kvm" "libvirtd" "qemu-libvirtd" ];
    })

    # Configure the VMs to be run on the host including systemd integration
    #
    (lib.mkIf (cfg.vms != {}) {
      hardware.ksm.enable = lib.mkDefault true;

      systemd.services = builtins.foldl' (result: hostname: result // (
      let
        vm = cfg.vms.${hostname};
      in
      {
        "qemu-${hostname}" = {
          description = "Run QEMU ${hostname}";

          # Requiring something that doesn't exist won't stop it from starting only log a warning
          requires = [
            "qemu-macvtap-${hostname}.service"
          ];

          # Configuring after for a unit that doesn't exist will just be ignored
          after = [
            "network.target"
            "qemu-macvtap-${hostname}.service"
          ];
          unitConfig.ConditionPathExists = "${cfg.stateDir}/${hostname}/result/bin/run";
          restartIfChanged = false;
          serviceConfig = {
            Type = "simple";
            WorkingDirectory = "${cfg.stateDir}/${hostname}";
            ExecStart = "${cfg.stateDir}/${hostname}/result/bin/run";
            ExecStop = "${cfg.stateDir}/${hostname}/result/bin/shutdown";
            TimeoutStopSec = 150;
            Restart = "always";
            RestartSec = "5s";
            User = cfg.machine.user.name;
            Group = cfg.group;
            SyslogIdentifier = "qemu-${hostname}";
            LimitNOFILE = 1048576;
            NotifyAccess = "all";
            LimitMEMLOCK = "infinity";
          };
        };
        "qemu-macvtap-${hostname}" = lib.mkIf (vm.interface == "macvtap") {
          description = "Setup QEMU ${hostname} MACVTAP interfaces";
          before = [ "qemu-${hostname}.service" ];
          partOf = [ "qemu-${hostname}.service" ];
          unitConfig.ConditionPathExists = "${cfg.stateDir}/${hostname}/result/bin/macvtap-up";
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            SyslogIdentifier = "qemu-macvtap-${hostname}";
            ExecStart = "${cfg.stateDir}/${hostname}/result/bin/macvtap-up";
            ExecStop = "${cfg.stateDir}/${hostname}/result/bin/macvtap-down";
          };
        };
      })) { } (builtins.attrNames cfg.vms);
    })
  ];
}
