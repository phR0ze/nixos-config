{ config, pkgs, lib, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation.qemu.guest;

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
      [ ! -d "${machine.hostname}" ] && echo "Must be run from the flake directory" && exit 1
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
        ${pkgs.e2fsprogs}/bin/mkfs.ext4 -L ${cfg.rootDrive.label} "$temp"
        ${cfg.package}/bin/qemu-img convert -f raw -O qcow2 "$temp" "''$${cfg.rootDrive.pathVar}"
        rm "$temp"
        echo "Root disk image created."
      fi

      # Other options to investigate
      # ----------------------------------------------------------------------------------------
      # -nodefaults                           # Don't include any default devices to contend with
      # -no-user-config                       # Don't include any system configuration to contend with
      # -no-reboot                            # Exit instead of rebooting
      #
      # MicroVM mode allows for higher performance
      # -M 'microvm,accel=kvm,acpi=on,mem-merge=on,pcie=on,pic=off,pit=off,usb=off'
          
      # -device i8042                         # Add keyboard controller i8042 to handle CtrlAltDel
      # -sandbox on                           # Disable system calls not needed by QEMU
      # -qmp unix:my-vm.sock,server,nowait    # Control socket to use
      # -object 'memory-backend-memfd,id=mem,size=4096M,share=on'
      # -numa 'node,memdev=mem'               # Simulate a multi node NUMA system

      # Launch the virtual machine
      # ----------------------------------------------------------------------------------------
      exec ${cfg.package}/bin/qemu-system-x86_64 \
        ${lib.concatStringsSep " \\\n  " cfg.options}
    '';
  };
}
