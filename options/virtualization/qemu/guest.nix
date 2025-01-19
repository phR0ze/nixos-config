# QEMU guest configuration
#
#---------------------------------------------------------------------------------------------------
{ modulesPath, config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.virtualisation;
  qemu = cfg.qemu.package;
  host = config.virtualization.qemu.host;
  rootFilesystemLabel = "nixos";

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

  # Networking qemu option line generation
  # --------------------------------------
  # -netdev 'tap,id=vm-prod1,fd=3' \
  # -device 'virtio-net-pci,netdev=vm-prod1,mac=02:00:00:00:00:01' \
  networkingOptLine = interfaces: let
    lines = builtins.concatMap (x: [
      "-netdev tap,id=${x.id},fd=${toString x.fd}"
      "-device virtio-net-pci,netdev=${x.id},mac=${x.mac}"
    ] ) interfaces;
  in if (builtins.length interfaces == 0) then
      lib.concatStringsSep " " config.virtualisation.qemu.networkingOptions
    else lib.concatStringsSep " " lines;

  # Script to start the macvtap
  macvtapUp = ''
    #! ${pkgs.runtimeShell}

    set -eou pipefail
    '' + lib.concatMapStrings ({ id, mac, macvtap, ... }: ''
      if [ -e /sys/class/net/${id} ]; then
        ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
      fi
      ${lib.getExe' pkgs.iproute2 "ip"} link add link '${macvtap.link}' name '${id}' address '${mac}' type macvtap mode '${macvtap.mode}'
      ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' allmulticast on
      if [ -f "/proc/sys/net/ipv6/conf/${id}/disable_ipv6" ]; then
        echo 1 > "/proc/sys/net/ipv6/conf/${id}/disable_ipv6"
      fi
      ${lib.getExe' pkgs.iproute2 "ip"} link set '${id}' up
      ${pkgs.coreutils-full}/bin/chown '${host.user}:${host.group}' /dev/tap$(< "/sys/class/net/${id}/ifindex")
    '') config.virtualization.qemu.guest.interfaces;

  # Script to stop the macvtap
  macvtapDown = ''
    #! ${pkgs.runtimeShell}

    set -eou pipefail
    '' + lib.concatMapStrings ({ id, ... }: ''
      if [ -e /sys/class/net/${id} ]; then
        ${lib.getExe' pkgs.iproute2 "ip"} link delete '${id}'
      fi
    '') config.virtualization.qemu.guest.interfaces;

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
    # -object 'memory-backend-memfd,id=mem,size=4096M,share=on'
    # -numa 'node,memdev=mem'               # Simulate a multi node NUMA system
    #
    # Binary choice
    # qemu-kvm is an older packaging concept, use qemu-system-x86_64 -enable-kvm instead
    #
    # -append 'earlyprintk=ttyS0 console=ttyS0 reboot=t panic=-1 root=fstab loglevel=4 init=/nix/store/z6s85j7d6xmg32wkfnkqy0llgrxcqdv2-nixos-system-vm-prod1-25.05.20241213.3566ab7/init regInfo=/nix/store/0h2vqibxaimm3km7d8h81v62fjvknlr0-closure-info/registration' \
    #
    # -fsdev 'local,id=fs0,path=/nix/store,security_model=none' \
    # -device 'virtio-9p-pci,fsdev=fs0,mount_tag=ro-store' \
    # 
    # Macvtap interface
    # -netdev 'tap,id=vm-prod1,fd=3' \
    # -device 'virtio-net-pci,netdev=vm-prod1,mac=02:00:00:00:00:01,romfile=' \
    # 
    # User nat interface
    # -net nic,netdev=user.0,model=virtio -netdev user,id=user.0,"$QEMU_NET_OPTS" \
    #
    exec ${qemu}/bin/qemu-system-x86_64 \
      -name ${config.system.name} \
      -enable-kvm \
      -machine accel=kvm:tcg \
      -cpu host,+x2apic,-sgx \
      -m ${toString machine.vm.memorySize} \
      -smp ${toString machine.vm.cores} \
      -device virtio-rng-pci \
      ${networkingOptLine config.virtualization.qemu.guest.interfaces} \
      ${lib.concatStringsSep " \\\n  "
        (lib.mapAttrsToList
          (tag: share: "-virtfs local,path=${share.source},security_model=none,mount_tag=${tag}")
          config.virtualisation.sharedDirectories)} \
      ${drivesOptLine config.virtualisation.qemu.drives} \
      ${lib.concatStringsSep " \\\n  " config.virtualisation.qemu.options} \
      $QEMU_OPTS \
      "$@"
  '';
in
{
  imports = [
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  options = {
    virtualization.qemu.guest = {
      enable = lib.mkEnableOption "Configure the VM's guest OS";

      interfaces = lib.mkOption {
        description = "Network interfaces";
        default = [];
        type = types.listOf (types.submodule {
          options = {
            type = lib.mkOption {
              type = types.enum [ "macvtap" ];
              description = "Interface type";
            };
            id = lib.mkOption {
              type = types.str;
              description = ''
                Interface name on the host. Shows up in the `ip a` listing e.g. `vm-prod1@enp1s0`
              '';
              example = "vm-prod1";
            };
            fd = lib.mkOption {
              type = types.int;
              description = ''
                Macvtap file descriptor number. Use something unique and count up e.g. 3
              '';
              example = 3;
            };
            macvtap.link = lib.mkOption {
              type = types.str;
              description = "Host NIC to attach to";
            };
            macvtap.mode = lib.mkOption {
              type = types.enum [ "bridge" ];
              description = "The MACVTAP mode to use";
            };
            mac = lib.mkOption {
              type = types.str;
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
        ln -s ${pkgs.writeScript "run-${machine.hostname}" runVM} $out/bin/run
        ln -s ${pkgs.writeScript "macvtap-up" macvtapUp} $out/bin/macvtap-up
        ln -s ${pkgs.writeScript "macvtap-down" macvtapDown} $out/bin/macvtap-down
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
