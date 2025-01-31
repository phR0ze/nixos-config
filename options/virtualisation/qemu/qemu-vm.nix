{ modulesPath, config, lib, pkgs, options, ... }: with lib;
let
  machine = config.machine;
  guest = config.virtualisation.qemu.guest;
  cfg = config.virtualisation;
  opt = options.virtualisation;
  hostPkgs = cfg.host.pkgs;
  consoles = lib.concatMapStringsSep " " (c: "console=${c}") cfg.qemu.consoles;

  regInfo = hostPkgs.closureInfo { rootPaths = config.virtualisation.additionalPaths; };

  # Use well-defined and persistent filesystem labels to identify block devices.
  rootFilesystemLabel = "nixos";
  espFilesystemLabel = "ESP"; # Hard-coded by make-disk-image.nix
  nixStoreFilesystemLabel = "nix-store";

  # System image is akin to a complete NixOS install with
  # a boot partition and root partition.
  systemImage = import (modulesPath + "../lib/make-disk-image.nix") {
    inherit pkgs config lib;
    additionalPaths = [ regInfo ];
    format = "qcow2";
    onlyNixStore = false;
    label = rootFilesystemLabel;
    partitionTableType = "legacy";
    installBootLoader = false;
    touchEFIVars = false;
    diskSize = "auto";
    additionalSpace = "0M";
    copyChannel = false;
    OVMF = cfg.efi.OVMF;
  };

  storeImage = import (modulesPath + "../lib/make-disk-image.nix") {
    name = "nix-store-image";
    inherit pkgs config lib;
    additionalPaths = [ regInfo ];
    format = "qcow2";
    onlyNixStore = true;
    label = nixStoreFilesystemLabel;
    partitionTableType = "none";
    installBootLoader = false;
    touchEFIVars = false;
    diskSize = "auto";
    additionalSpace = "0M";
    copyChannel = false;
  };

in

{
  options = {
    virtualisation.fileSystems = options.fileSystems;

    virtualisation.msize =
      mkOption {
        type = types.ints.positive;
        default = 16384;
        description =
          lib.mdDoc ''
            The msize (maximum packet size) option passed to 9p file systems, in
            bytes. Increasing this should increase performance significantly,
            at the cost of higher RAM usage.
          '';
      };

    virtualisation.rootDevice =
      mkOption {
        type = types.nullOr types.path;
        default = "/dev/disk/by-label/${rootFilesystemLabel}";
        defaultText = literalExpression ''/dev/disk/by-label/${rootFilesystemLabel}'';
        example = "/dev/disk/by-label/nixos";
        description =
          lib.mdDoc ''
            The path (inside the VM) to the device containing the root filesystem.
          '';
      };

    virtualisation.emptyDiskImages =
      mkOption {
        type = types.listOf types.ints.positive;
        default = [];
        description =
          lib.mdDoc ''
            Additional disk images to provide to the VM. The value is
            a list of size in megabytes of each disk. These disks are
            writeable by the VM.
          '';
      };

    virtualisation.additionalPaths =
      mkOption {
        type = types.listOf types.path;
        default = [];
        description =
          lib.mdDoc ''
            A list of paths whose closure should be made available to
            the VM.

            When 9p is used, the closure is registered in the Nix
            database in the VM. All other paths in the host Nix store
            appear in the guest Nix store as well, but are considered
            garbage (because they are not registered in the Nix
            database of the guest).

            When {option}`virtualisation.useNixStoreImage` is
            set, the closure is copied to the Nix store image.
          '';
      };

    virtualisation.host.pkgs = mkOption {
      type = options.nixpkgs.pkgs.type;
      default = pkgs;
      defaultText = literalExpression "pkgs";
      example = literalExpression ''
        import pkgs.path { system = "x86_64-darwin"; }
      '';
      description = lib.mdDoc ''
        Package set to use for the host-specific packages of the VM runner.
        Changing this to e.g. a Darwin package set allows running NixOS VMs on Darwin.
      '';
    };

    virtualisation.qemu = {
      options =
        mkOption {
          type = types.listOf types.str;
          default = [];
          example = [ "-vga std" ];
          description = lib.mdDoc "Options passed to QEMU.";
        };

      consoles = mkOption {
        type = types.listOf types.str;
        default = let
          consoles = [ "ttyS0,115200n8" "tty0" ];
        in if guest.display.enable then consoles else reverseList consoles;
        example = [ "console=tty1" ];
        description = lib.mdDoc ''
          The output console devices to pass to the kernel command line via the
          `console` parameter, the primary console is the last
          item of this list.

          By default it enables both serial console and
          `tty0`. The preferred console (last one) is based on
          the value of {option}`virtualisation.graphics`.
        '';
      };
    };

    virtualisation.directBoot = {
      enable =
        mkOption {
          type = types.bool;
          default = true;
          description =
            lib.mdDoc ''If enabled, the virtual machine will boot directly into the kernel instead 
            of through a bootloader.
            '';
        };
      initrd =
        mkOption {
          type = types.str;
          default = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
          defaultText = "\${config.system.build.initialRamdisk}/\${config.system.boot.loader.initrdFile}";
          description =
            lib.mdDoc ''
              In direct boot situations, you may want to influence the initrd load to use your own 
              customized payload.
            '';
        };
    };
  };

  config = {
    # After booting, register the closure of the paths in
    # `virtualisation.additionalPaths' in the Nix database in the VM.  This
    # allows Nix operations to work in the VM.  The path to the
    # registration file is passed through the kernel command line to
    # allow `system.build.toplevel' to be included.  (If we had a direct
    # reference to ${regInfo} here, then we would get a cyclic
    # dependency.)
    boot.postBootCommands = lib.mkIf config.nix.enable
      ''
        if [[ "$(cat /proc/cmdline)" =~ regInfo=([^ ]*) ]]; then
          ${config.nix.package.out}/bin/nix-store --load-db < ''${BASH_REMATCH[1]}
        fi
      '';

    virtualisation.additionalPaths = [ config.system.build.toplevel ];

    virtualisation.qemu.options = mkMerge [
      (let
        alphaNumericChars = lowerChars ++ upperChars ++ (map toString (range 0 9));
        # Replace all non-alphanumeric characters with underscores
        sanitizeShellIdent = s: concatMapStrings (c: if builtins.elem c alphaNumericChars then c else "_") (stringToCharacters s);
      in mkIf cfg.directBoot.enable [
        "-kernel \${NIXPKGS_QEMU_KERNEL_${sanitizeShellIdent config.system.name}:-${config.system.build.toplevel}/kernel}"
        "-initrd ${cfg.directBoot.initrd}"
        ''-append "$(cat ${config.system.build.toplevel}/kernel-params) init=${config.system.build.toplevel}/init regInfo=${regInfo}/registration ${consoles} $QEMU_KERNEL_PARAMS"''
      ])
    ];

    boot.initrd.systemd = lib.mkIf (config.boot.initrd.systemd.enable) {
      mounts = [{
        where = "/sysroot/nix/store";
        what = "overlay";
        type = "overlay";
        options = "lowerdir=/sysroot/nix/.ro-store,upperdir=/sysroot/nix/.rw-store/store,workdir=/sysroot/nix/.rw-store/work";
        wantedBy = ["initrd-fs.target"];
        before = ["initrd-fs.target"];
        requires = ["rw-store.service"];
        after = ["rw-store.service"];
        unitConfig.RequiresMountsFor = "/sysroot/nix/.ro-store";
      }];
      services.rw-store = {
        unitConfig = {
          DefaultDependencies = false;
          RequiresMountsFor = "/sysroot/nix/.rw-store";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "/bin/mkdir -p -m 0755 /sysroot/nix/.rw-store/store /sysroot/nix/.rw-store/work /sysroot/nix/store";
        };
      };
    };

    swapDevices = mkVMOverride [ ];
    boot.initrd.luks.devices = mkVMOverride {};

    # When building a regular system configuration, override whatever
    # video driver the host uses.
    services.xserver.videoDrivers = mkVMOverride [ "modesetting" ];
    services.xserver.defaultDepth = mkVMOverride 0;
    services.xserver.resolutions = mkVMOverride [ machine.resolution ];
    services.xserver.monitorSection =
      ''
        # Set a higher refresh rate so that resolutions > 800x600 work.
        HorizSync 30-140
        VertRefresh 50-160
      '';
  };
}
