# QEMU host configuration

# The following kernel params already setup in nixos-config/modules/boot/kerel.nix are required
# ```nix
# boot.kernel.sysctl = {
#   "net.ipv4.ip_forward" = 1;
#   "net.bridge.bridge-nf-call-arptables" = 0;
#   "net.bridge.bridge-nf-call-ip6tables" = 0;
#   "net.bridge.bridge-nf-call-iptables" = 0;
# };
# ```
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  host = config.host;
  cfg = config.virtualization.qemu.host;

  # secret admin user's name and group can only be accessessed at runtime by root for security
  userSecretPath = config.secret.files."users/admin/name".path;
  groupSecretPath = config.secret.files."users/admin/group".path;

  # Drop root to the real (uid, gid) pair at process-start time instead of via a static
  # serviceConfig User=/Group=, since the real gid isn't known until this path is read.
  # --init-groups re-derives supplementary groups (e.g. "kvm") from the real account.
  dropPriv = label: cmd: pkgs.writeShellScript "qemu-${label}" ''
    #!${pkgs.runtimeShell}
    set -e
    exec ${pkgs.util-linux}/bin/setpriv \
      --reuid "$(cat ${userSecretPath})" --regid "$(cat ${groupSecretPath})" \
      --clear-groups --init-groups -- ${cmd}
  '';

  macvtapInterfaces = builtins.filter (hostname:
    cfg.vms.${hostname}.interface == "macvtap"
  ) (builtins.attrNames cfg.vms);
in
{
  options = {
    virtualization.qemu.host = {
      enable = lib.mkEnableOption "Install and configure QEMU on the host system";
      package = lib.mkOption {
        description = "Default QEMU package to use";
        type = types.package;
        default = pkgs.qemu_kvm;
      };
      stateDir = lib.mkOption {
        type = types.path;
        default = "/var/lib/vms";
        description = "Directory that contains the VMs";
      };
      vms = lib.mkOption {
        description = "Virtual machines";
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
        default = {};
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.system.users.admin.enable;
          message = "virtualization.qemu.host requires system.users.admin.enable (needed to resolve the real admin group at runtime)";
        }
      ];

      # Make the secret admin name runtime accessible by root. modules/system/users.nix already
      # declares "users/admin/group" this way; the name isn't declared anywhere else (nix-weave
      # keeps its own copy under the private _users-from-secret/ prefix), so declare it here.
      # Same sopsFile as system.users, so any overlapping definition merges rather than conflicts.
      secret.files."users/admin/name" = {
        filemode = "0400";
        sopsFile = config.system.users.sopsFile;
      };

      # Create an activation script to ensure that the VM state directory exists. Ordered after
      # nix-weave's own account-creation script so the real group already exists on the system
      # before we chown to it.
      system.activationScripts.vm-host = lib.stringAfter [ "usersFromSecret" ] ''
        mkdir -p ${cfg.stateDir}
        chown "$(cat ${userSecretPath})":"$(cat ${groupSecretPath})" ${cfg.stateDir}
        chmod g+w ${cfg.stateDir}
      '';

      # Remove memory constraints for the vm user.
      # Keyed on the '@wheel' group rather than the admin account name: pam_limits is handed a
      # store baked limits.conf (nixpkgs passes `conf=` explicitly, so /etc/security/limits.d is
      # never consulted), which means the domain has to be known at evaluation time - and the
      # admin's name is a runtime only secret. modules/system/users.nix puts admin in 'wheel'.
      security.pam.loginLimits = [ {
        domain = "@wheel";
        item = "memlock";
        type = "hard";
        value = "infinity";
      } {
        domain = "@wheel";
        item = "memlock";
        type = "soft";
        value = "infinity";
      } ];

      # Needed?
#      virtualisation.libvirtd = {
#        enable = true;
#        qemu.swtpm.enable = true;                   # Configure windows swtpm
#        qemu.ovmf.enable = true;                    # Configure UEFI support
#        qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];  # Configure UEFI support
#        qemu.vhostUserPackages = [ pkgs.virtiofsd ];  # virtiofs support
#      };

      environment.sessionVariables.LIBVIRT_DEFAULT_URI = [ "qemu:///system" ];

      # Enables the use of qemu-bridge-helper for `type = "bridge"` interface.
      environment.etc."qemu/bridge.conf".text = lib.mkForce ''
        allow ${host.net.bridge.name}
      '';

      # Allow qemu-bridge-helper to create tap interfaces and attach them to
      # the bridge without being root
      security.wrappers.qemu-bridge-helper = {
        setuid = true;
        owner = "root";
        group = "root";
        source = "${cfg.package}/libexec/qemu-bridge-helper";
      };

      # Allow nested virtualisation
      # Set in the modules/hardware/kernel.nix file
      #boot.extraModprobeConfig = "options kvm_intel nested=1";

      services.spice-webdavd.enable = true;             # File sharing support between Host and Guest
      virtualisation.spiceUSBRedirection.enable = true; # Support USB passthrough to VMs from host

      # Additional packages
      environment.systemPackages = with pkgs; [
        qemu              # Base QEMU binary
        quickemu          # QEMU wrapper that gives good insights
        spice-gtk         # Provides GTK SPICE client `spicy`
        spice-protocol    # SPICE support
        virglrenderer     # Support Guests using Virtio ro get host OpenGL acceleration
        virt-viewer       # Provides SPICE client `remote-viewer spice:://<host>:5900`
        virtio-win        # QEMU support for windows
        win-spice         # SPICE support for windows
      ];

      secret.users."admin".extraGroups = [ "kvm" ];
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
            # Starts as root; dropPriv resolves the real (uid, gid) at process-start time and
            # drops to it before exec'ing the actual run/shutdown script (see the `group` comment
            # in this file's `let` block for why User=/Group= can't be used directly here).
            ExecStart = "${dropPriv "${hostname}-run" "${cfg.stateDir}/${hostname}/result/bin/run"}";
            ExecStop = "${dropPriv "${hostname}-shutdown" "${cfg.stateDir}/${hostname}/result/bin/shutdown"}";
            TimeoutStopSec = 150;
            Restart = "always";
            RestartSec = "5s";
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
