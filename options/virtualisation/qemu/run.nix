{ config, pkgs, lib, ... }: with lib.types;
let
  cfg = config.virtualisation;
  guest = config.virtualisation.qemu.guest;
  rootFilesystemLabel = "nixos";

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) guest.interfaces;
  macvtapInterfaces = interfacesByType "macvtap";

  # Drive qemu option line generation
  # --------------------------------------
  driveOptLine = idx: { file, driveExtraOpts, deviceExtraOpts, ... }:
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
  drivesOptLine = drives: lib.concatStringsSep "\\\n    " (lib.imap1 driveOptLine drives);
in
{
  config = {
    virtualisation.qemu.guest.scripts.run = ''
      #! ${pkgs.runtimeShell}

      export PATH=${lib.makeBinPath [ pkgs.coreutils ]}''${PATH:+:}$PATH
      set -e

      ${if (macvtapInterfaces != []) then ''
      # Open the tap device with the given file descriptor for read/write. Starting with 3 is typical
      # since 0, 1, and 2 are used for standard input, output and error.
      # ----------------------------------------------------------------------------------------------
      '' + lib.concatMapStrings ({id, fd, ...}:
        "exec ${toString fd}<>/dev/tap$(< /sys/class/net/${id}/ifindex)"
      ) macvtapInterfaces else ""}

      # Create an empty ext4 filesystem image to store VM state
      # ----------------------------------------------------------------------------------------------
      NIX_DISK_IMAGE=$(readlink -f "${toString cfg.diskImage}")
      if ! test -e "$NIX_DISK_IMAGE"; then
        echo "Disk image does not exist, creating $NIX_DISK_IMAGE..."
        temp=$(mktemp)
        size="${toString cfg.diskSize}M"
        ${cfg.qemu.package}/bin/qemu-img create -f raw "$temp" "$size"
        ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L ${rootFilesystemLabel} "$temp"
        ${cfg.qemu.package}/bin/qemu-img convert -f raw -O qcow2 "$temp" "$NIX_DISK_IMAGE"
        rm "$temp"
        echo "Virtualisation disk image created."
      fi

      # Create dir storing VM running data and a sub-dir for exchanging data with the VM
      # ----------------------------------------------------------------------------------------------
      TMPDIR=$(mktemp -d nix-vm.XXXXXXXXXX --tmpdir)
      mkdir -p "$TMPDIR/xchg"
      cd "$TMPDIR"

      # [QEMU launch options](https://qemu-project.gitlab.io/qemu/system/invocation.html)
      # ----------------------------------------------------------------------------------------------
      # Name of the guest used in the default SDL window caption or the VNC window and Linux process
      # -name my-vm

      # QEMU suupport two x86 chipsets. The ancient (1996) i440FX and the more recent (2007) Q35. Q35 
      # is the go forward strategy supporting PCIe natively. 
      # * System Management Mode (SMM) is part of secure boot and not needed for typical VMs.
      # * '--enable-kvm' is the old way and 'accel=kvm' is the new way but they are the same.
      # * 'vmport=off' to disable VMWare IO port emulation
      # -machine q35,smm=off,vmport=off,accel=kvm

      # Optimal performance is found with host cpu type and x2apic enabled. x2apic is a performance and 
      # scalabilty feature available in many modern intel CPUs. Regardless of host support KVM can 
      # emulate it for x86 guests with no downside, so always enable it.
      # * enable x2apic: https://blog.wikichoon.com/2014/11/x2apic-on-by-default-with-qemu-20-and.html
      # * disabling sgx: https://gitlab.com/qemu-project/qemu/-/issues/2142
      # * -cpu max means emulate all features limited by host support, not as performant as -cpu host
      # -cpu host,+x2apic,-sgx

      # VirtIO Memory Ballooning allows the host and guest to more intelligently manage memory such 
      # that the host can reclaim and negociate with the guest how much is used.
      # -device virtio-balloon

      # Although you can specify cores,threads,sockets there isn't any benefit performance wise.
      # -smp 4                                # Number of virtual CPUs

      # -m 4G                                 # Memory in GB
      # -nographic                            # Disable the local GUI window
      # -device virtio-rng-pci                # Use a virtio driver for randomness
      # -nodefaults                           # Don't include any default devices to contend with
      # -no-user-config                       # Don't include any system configuration to contend with
      # -no-reboot                            # Exit instead of rebooting
      # -chardev 'stdio,id=stdio,signal=off'  # Connect QEMU Stdin/Stdout to shell
      # -serial chardev:stdio                 # Redirect serial to 'stdio' instead of 'vc' for graphical mode
      #
      # MicroVM mode allows for higher performance
      # -M 'microvm,accel=kvm:tcg,acpi=on,mem-merge=on,pcie=on,pic=off,pit=off,usb=off'
          
      # -device i8042                         # Add keyboard controller i8042 to handle CtrlAltDel
      # -sandbox on                           # Disable system calls not needed by QEMU
      # -qmp unix:my-vm.sock,server,nowait    # Control socket to use
      # -object 'memory-backend-memfd,id=mem,size=4096M,share=on'
      # -numa 'node,memdev=mem'               # Simulate a multi node NUMA system
      #
      # Binary choice
      # qemu-kvm is an older packaging concept, use qemu-system-x86_64 -enable-kvm instead
      #
      # -append 'earlyprintk=ttyS0 console=ttyS0 reboot=t panic=-1 root=fstab loglevel=4 init=/nix/store/z6s85j7d6xmg32wkfnkqy0llgrxcqdv2-nixos-system-vm-prod1-25.05.20241213.3566ab7/init regInfo=/nix/store/0h2vqibxaimm3km7d8h81v62fjvknlr0-closure-info/registration' \
      #
      # -fsdev local,id=fs0,path=/nix/store,security_model=none
      # -device virtio-9p-pci,fsdev=fs0,mount_tag=ro-store
      # 
      # Macvtap interface:
      # -netdev tap,id=vm-prod1,fd=3 -device 'virtio-net-pci,netdev=vm-prod1,mac=02:00:00:00:00:01
      # 
      # User nat interface:
      # -net nic,netdev=vm-prod1,model=virtio -netdev user,id=vm-prod1
      #
      exec ${cfg.qemu.package}/bin/qemu-system-x86_64 \
        -name ${config.machine.hostname} -machine q35,smm=off,vmport=off,accel=kvm \
        -smp ${toString guest.cores} -cpu host,+x2apic,-sgx \
        -m ${toString guest.memorySize}G -device virtio-balloon \
        -device virtio-rng-pci \
        ${lib.concatStringsSep " \\\n  " guest.networkingArgs} \
        ${lib.concatStringsSep " \\\n  "
          (lib.mapAttrsToList
            (tag: share: "-virtfs local,path=${share.source},security_model=none,mount_tag=${tag}")
            config.virtualisation.sharedDirectories)} \
        ${drivesOptLine cfg.qemu.drives} \
        ${lib.concatStringsSep " \\\n  " cfg.qemu.options} \
        $QEMU_OPTS \
        "$@"
    '';
  };
}
