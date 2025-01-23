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
            };
            autostart = lib.mkOption {
              description = lib.mdDoc "Start the VM when the host system boots";
              type = types.bool;
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

      # Allow qemu-bridge-helper to create tap interfaces and attach them to
      # a bridge without being root
      security.wrappers.qemu-bridge-helper = {
        source = "${pkgs.qemu-utils}/libexec/qemu-bridge-helper";
        owner = "root";
        group = "root";
        capabilities = "cap_net_admin+ep";
      };

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

    (lib.mkIf (cfg.vms != {}) {
      hardware.ksm.enable = lib.mkDefault true;

      # The @ symbol turns the unit file into a template. The value after the @ symbol is passed 
      # into the unit as %i. In this way the unit can be instantiated multiple times.
      systemd.services = builtins.foldl' (result: hostname: result // (
      let
        vm = cfg.vms.${hostname};
      in
      {
        "qemu@" = {

        };
      })) {
        # Main 
        "qemu@" = {
          description = "QEMU VM '%i'";

          # Requiring something that doesn't exist won't stop it from starting only log a warning
          requires = [
            "qemu-macvtap@%i.service"
          ];

          # Configuring after for a unit that doesn't exist will just be ignored
          after = [
            "network.target"
            "qemu-macvtap@%i.service"
          ];
          unitConfig.ConditionPathExists = "${cfg.stateDir}/%i/result/bin/run";
          restartIfChanged = false;
          serviceConfig = {
            Type =
              if config.microvm.host.useNotifySockets
              then "notify"
              else "simple";
            WorkingDirectory = "${cfg.stateDir}/%i";
            ExecStart = "${cfg.stateDir}/%i/result/bin/run";
            ExecStop = "${cfg.stateDir}/%i/result/bin/shutdown";
            TimeoutStopSec = 150;
            Restart = "always";
            RestartSec = "5s";
            User = cfg.user;
            Group = cfg.group;
            SyslogIdentifier = "qemu@%i";
            LimitNOFILE = 1048576;
            NotifyAccess = "all";
            LimitMEMLOCK = "infinity";
          };
        };

        "qemu-macvtap@" = lib.mkIf (macvtapInterfaces != []) {
          description = "Setup '%i' MACVTAP interfaces";
          before = [ "qemu@%i.service" ];
          partOf = [ "qemu@%i.service" ];
          unitConfig.ConditionPathExists = "${cfg.stateDir}/%i/result/bin/macvtap-up";
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            SyslogIdentifier = "qemu-macvtap@%i";
            ExecStart = "${cfg.stateDir}/%i/result/bin/macvtap-up";
            ExecStop = "${cfg.stateDir}/%i/result/bin/macvtap-down";
          };
        };
      } (builtins.attrNames cfg.vms);
    })
  ];
}
