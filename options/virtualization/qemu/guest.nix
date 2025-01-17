# QEMU guest configuration
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }:
let
  machine = config.machine;
  cfg = config.virtualisation;
  qemu = cfg.qemu.package;
  rootFilesystemLabel = "nixos";

  driveCmdline = idx: { file, driveExtraOpts, deviceExtraOpts, ... }:
    let
      drvId = "drive${toString idx}";
      mkKeyValue = lib.generators.mkKeyValueDefault {} "=";
      mkOpts = opts: lib.concatStringsSep "," (lib.mapAttrsToList mkKeyValue opts);
      driveOpts = mkOpts (driveExtraOpts // {
        index = idx;
        id = drvId;
        "if" = "none";
        inherit file;
      });
      deviceOpts = mkOpts (deviceExtraOpts // {
        drive = drvId;
      });
    in
      "-drive ${driveOpts} \\\n  -device virtio-blk-pci,${deviceOpts}";

  drivesCmdLine = drives: lib.concatStringsSep "\\\n    " (lib.imap1 driveCmdline drives);

  # Script to run the VM
  runVM = ''
    #! ${pkgs.runtimeShell}

    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}''${PATH:+:}$PATH
    set -e

    # Create an empty ext4 filesystem image to store VM state
    # ----------------------------------------------------------------------------------------------
    NIX_DISK_IMAGE=$(readlink -f "${toString cfg.diskImage}")
    if ! test -e "$NIX_DISK_IMAGE"; then
      echo "Disk image does not exist, creating $NIX_DISK_IMAGE..."
      temp=$(mktemp)
      size="${toString cfg.diskSize}M"
      ${qemu}/bin/qemu-img create -f raw "$temp" "$size"
      ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L ${rootFilesystemLabel} "$temp"
      ${qemu}/bin/qemu-img convert -f raw -O qcow2 "$temp" "$NIX_DISK_IMAGE"
      rm "$temp"
      echo "Virtualisation disk image created."
    fi

    # Create dir storing VM running data and a sub-dir for exchanging data with the VM
    # ----------------------------------------------------------------------------------------------
    TMPDIR=$(mktemp -d nix-vm.XXXXXXXXXX --tmpdir)
    mkdir -p "$TMPDIR/xchg"
    cd "$TMPDIR"

    # Launch QEMU
    # ----------------------------------------------------------------------------------------------
    # -name my-vm                           # VM name shown in windows and used as an identifier
    # -m 4096                               # Memory in megabytes
    # -smp 1                                # Virtual CPUs
    # -nographic                            # Disable the local GUI window
    # -device virtio-rng-pci                # Use a virtio driver for randomness
    # -nodefaults                           # Don't include any default devices to contend with
    # -no-user-config                       # Don't include any system configuration to contend with
    # -no-reboot                            # Exit instead of rebooting
    # -chardev 'stdio,id=stdio,signal=off'  # Connect QEMU Stdin/Stdout to shell
    # -serial chardev:stdio                 # Redirect serial to 'stdio' instead of 'vc' for graphical mode
    # -enable-kvm                           # Enable full KVM virtualzation support
    #
    # MicroVM mode allows for higher performance
    # -M 'microvm,accel=kvm:tcg,acpi=on,mem-merge=on,pcie=on,pic=off,pit=off,usb=off'
    #
    # Optimal performance is found with host cpu type and x2apic enabled. x2apic is a performance and 
    # scalabilty feature available in many modern intel CPUs. Regardless of host support KVM can 
    # emulate it for x86 guests with no downside, so always enable it.
    # * enable x2apic: https://blog.wikichoon.com/2014/11/x2apic-on-by-default-with-qemu-20-and.html
    # * disabling sgx: https://gitlab.com/qemu-project/qemu/-/issues/2142
    # * -cpu max means emulate all features limited by host support, not as performant as -cpu host
    # -cpu host,+x2apic,-sgx
    #
    # -device i8042                         # Add keyboard controller i8042 to handle CtrlAltDel
    # -sandbox on                           # Disable system calls not needed by QEMU
    # -qmp unix:my-vm.sock,server,nowait    # Control socket to use
    # -numa 'node,memdev=mem'               # Simulate a multi node NUMA system

    # Binary choice
    # qemu-kvm is an older packaging concept, use qemu-system-x86_64 -enable-kvm instead

    exec ${qemu}/bin/qemu-system-x86_64 \
      -name ${config.system.name} \
      -enable-kvm \
      -machine microvm,accel=kvm:tcg \
      -cpu host,+x2apic,-sgx \
      -m ${toString config.virtualisation.memorySize} \
      -smp ${toString config.virtualisation.cores} \
      -device virtio-rng-pci \
      ${lib.concatStringsSep " " config.virtualisation.qemu.networkingOptions} \
      ${lib.concatStringsSep " \\\n  "
        (lib.mapAttrsToList
          (tag: share: "-virtfs local,path=${share.source},security_model=none,mount_tag=${tag}")
          config.virtualisation.sharedDirectories)} \
      ${drivesCmdLine config.virtualisation.qemu.drives} \
      ${lib.concatStringsSep " \\\n  " config.virtualisation.qemu.options} \
      $QEMU_OPTS \
      "$@"
  '';
in
{
  options = {
    virtualization.qemu.guest = {
      enable = lib.mkEnableOption "Configure the VM's guest OS";

      interfaces = lib.mkOption {
        description = "Network interfaces";
        default = [];
        type = with lib.types; lib.listOf (lib.submodule {
          options = {
            type = lib.mkOption {
              type = lib.enum [ "macvtap" ];
              description = "Interface type";
            };
            name = lib.mkOption {
              type = lib.str;
              description = "Interface name on the host";
            };
            macvtap.link = lib.mkOption {
              type = lib.str;
              description = "Host NIC to attach to";
            };
            macvtap.mode = lib.mkOption {
              type = lib.enum [ "bridge" ];
              description = "The MACVTAP mode to use";
            };
            mac = lib.mkOption {
              type = lib.str;
              description = ''
                MAC address of the guest's network interface. Setting it to a prefix of 02 indicates 
                that it is being adminstered locally. Then you can simply increment the final nibble 
                to provide unique identifiers for your VMs.
              '';
              example = "02:00:00:00:00:01";
            };
          };
        });
      };
    };
  };

  config = lib.mkMerge [

    (lib.mkIf (machine.type.vm) {
      services.qemuGuest.enable = true;             # Install and run the QEMU guest agent
      services.x11vnc.enable = lib.mkForce false;   # We'll use SPICE instead

      virtualisation = {
        cores = machine.vm.cores;                   # VM cores
        diskSize = machine.vm.diskSize;             # VM disk size
        memorySize = machine.vm.memorySize;         # VM memory size
        graphics = machine.vm.graphics;             # Enable or disable local window UI
        resolution = machine.resolution;            # Configure system resolution
        qemu.package = lib.mkForce pkgs.qemu_kvm;  # Ensure we have the standard KVM supported qemu

        # Allows for sftp, ssh etc... to the guest via localhost:2222
        #forwardPorts = [ { from = "host"; host.port = 2222; guest.port = 22; } ];
      };

      # Override and provide custom VM helper scripts
      system.build.vm = lib.mkForce (pkgs.runCommand "vm-${config.system.name}" { preferLocalBuild = true; } ''
        mkdir -p $out/bin
        ln -s ${config.system.build.toplevel} $out/system
        ln -s ${pkgs.writeScript "run-vm-${config.system.name}" runVM} $out/bin/run
      '');
    })

    # Optionally enable SPICE support
    # Connect by launching `remote-viewer` and running `spice://localhost:5970`
    (lib.mkIf (machine.type.vm && machine.vm.spice) {

      # Configure QEMU for SPICE
      virtualisation.qemu.options = [
        "-vga qxl"
        "-spice port=${toString machine.vm.spicePort},disable-ticketing=on"
        "-device virtio-serial"
        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];

      # Configure SPICE related services
      services.spice-vdagentd.enable = true;        # SPICE agent to be run on the guest OS
      services.spice-autorandr.enable = true;       # Automatically adjust resolution of guest to spice client size
      services.spice-webdavd.enable = true;         # Enable file sharing on guest to allow access from host

      # Configure higher performance graphics for SPICE
      services.xserver.videoDrivers = [ "qxl" ];
      environment.systemPackages = [ pkgs.xorg.xf86videoqxl ];

      # Open up the firewall for machine.vm.spicePort
      networking.firewall.allowedTCPPorts = [ machine.vm.spicePort ];
    })
  ];
}
