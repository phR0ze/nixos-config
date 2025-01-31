{ config, pkgs, lib, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.qemu.guest;
  fixme = config.virtualisation;

  # Block device labels for identification
  rootFilesystemLabel = "nixos";

  # Filter down the interfaces to the given type
  interfacesByType = wantedType:
    builtins.filter ({ type, ... }: type == wantedType) cfg.interfaces;
  macvtapInterfaces = interfacesByType "macvtap";
in
{
  config = {
    virtualisation.qemu.guest.scripts.run = ''
      #! ${pkgs.runtimeShell}

      export PATH=${lib.makeBinPath [ pkgs.coreutils ]}''${PATH:+:}$PATH
      set -e

      # Create dir storing VM running data and a sub-dir for exchanging data with the VM
      # ----------------------------------------------------------------------------------------------
      [ ! -d result ] && echo "Must be run from the VM directory" && exit 1
      VMDIR="${machine.hostname}"
      mkdir -p "$VMDIR/shared"
      cd "$VMDIR"
      VMDIR="$(pwd)"

      ${if (macvtapInterfaces != []) then ''
      # Open the tap device with the given file descriptor for read/write. Starting with 3 is typical
      # since 0, 1, and 2 are used for standard input, output and error.
      # ----------------------------------------------------------------------------------------------
      '' + lib.concatMapStrings ({id, fd, ...}:
        "exec ${toString fd}<>/dev/tap$(< /sys/class/net/${id}/ifindex)"
      ) macvtapInterfaces else ""}

      # Create an empty ext4 filesystem image to store VM state
      # ----------------------------------------------------------------------------------------------
      ${cfg.rootDrive.pathVar}=$(readlink -f "${cfg.rootDrive.image}")
      if ! test -e "''$${cfg.rootDrive.pathVar}"; then
        echo "Root disk image does not exist, creating ''$${cfg.rootDrive.pathVar}..."
        temp=$(mktemp)
        size="${toString (cfg.rootDrive.size * 1024)}M"
        ${cfg.package}/bin/qemu-img create -f raw "$temp" "$size"
        ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L ${rootFilesystemLabel} "$temp"
        ${cfg.package}/bin/qemu-img convert -f raw -O qcow2 "$temp" "''$${cfg.rootDrive.pathVar}"
        rm "$temp"
        echo "Root disk image created."
      fi

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
      # -M 'microvm,accel=kvm,acpi=on,mem-merge=on,pcie=on,pic=off,pit=off,usb=off'
          
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
      exec ${cfg.package}/bin/qemu-system-x86_64 \
        -name ${machine.hostname} -machine q35,smm=off,vmport=off,accel=kvm \
        -smp ${toString cfg.cores} -cpu host,+x2apic,-sgx \
        -m ${toString cfg.memorySize}G -device virtio-balloon \
        -pidfile ${machine.hostname}.pid \
        -device virtio-rng-pci \
        ${lib.concatStringsSep " \\\n  " fixme.qemu.options} \
        $QEMU_OPTS \
        "$@"
    '';
  };
}
