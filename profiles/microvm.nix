# MicroVM shared configuration
# ----------------------------------------------------------------------------------------------
#
# ### Research
# - https://github.com/astro/microvm.nix
#   - creates systemd units for tap, macvtap, virtiofsd and others
# - qemu introduced the microvm type which removes legacy clutter and is optimized for VirtIO which 
#   now makes it possible to use VMs much like containers only with more isolation and protection
#
# Nix standard VM QEMU values
# ----------------------------------------------------------------------------------------------
#   -net nic,netdev=user.0,model=virtio -netdev user,id=user.0,"$QEMU_NET_OPTS" \
#   -vga qxl \
#   -spice port=5970,disable-ticketing=on \
#   -device virtio-serial \
#   -chardev spicevmc,id=vdagent,debug=0,name=vdagent \
#   -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \

# Micro VM QEMU example run values and explanations
# ----------------------------------------------------------------------------------------------
# exec -a "microvm@my-vm" /nix/store/...-qemu-host-cpu-only-for-vm-tests-9.1.2/bin/qemu-system-x86_64
#
# # microvm machine type, disable USB
# # ------------------------------------
# -M 'microvm,accel=kvm:tcg,acpi=on,mem-merge=on,pcie=on,pic=off,pit=off,usb=off'
#
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
# -cpu host,+x2apic,-sgx                # Use host CPU and x2apic for max performance. Don't use sgx
# -device i8042                         # Add keyboard controller i8042 to handle CtrlAltDel
# -sandbox on                           # Disable system calls not needed by QEMU
# -qmp unix:my-vm.sock,server,nowait    # Control socket to use
# -numa 'node,memdev=mem'               # Simulate a multi node NUMA system
#
# -object 'memory-backend-memfd,id=mem,size=4096M,share=on'
#
# # Nix store sharing configuration
# # ------------------------------------
# -fsdev 'local,id=fs0,path=/nix/store,security_model=none'
# -device 'virtio-9p-pci,fsdev=fs0,mount_tag=ro-store'
#
# # Kernel and initrd configuration
# # ------------------------------------
# -kernel /nix/store/jzl52vx9j42jgn92nynihpniamzwd31p-linux-6.6.64/bzImage
# -initrd /nix/store/v4qgl2a1572a3mv8wq8x69insq7h6lw2-initrd-linux-6.6.64/initrd
# -append 'earlyprintk=ttyS0 console=ttyS0 reboot=t panic=-1 root=fstab loglevel=4 init=/nix/store/...-nixos-system-my-vm-25.05.20241213.3566ab7/init regInfo=/nix/store/...-closure-info/registration'
#
# # SPICE configuration
# # ------------------------------------
# '-vga qxl' '-spice port=5971,disable-ticketing=on' '-device virtio-serial' '-chardev spicevmc,id=vdagent,debug=0,name=vdagent' '-device virtserialport,chardev=vdagent,name=com.redhat.spice.0'
#
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  machine = config.machine;
in
{
  config = lib.mkMerge [
    {
      microvm = {
        guest.enable = true;                    # Enable guest module; default: true
        #optimize.enable = true;                # Turn off docs, default to systemd-networkd
        #cpu = "";                              # CPU type to emulate; defaul: host
        hypervisor = "qemu";                    # Hypervisor type to run; default: "qemu"
        #preStart = "";                         # Commands to run before starting the hypervisor
        #socket = "";                           # Hypervisor control socket; default: "$hostname.sock"
        #user = "";                             # User to switch to when started as root; default: null
        #kernel = "";                           # Kernel package to use; default: boot.kernelPackages.kernel
        #initrPath = "";                        # Path to the initrd file; default: system.boot...
        vcpu = machine.vm.cores;                # Number of virtual cpu cores; default: 1
        mem = machine.vm.memorySize;            # Amount of RAM in megabytes; default: 512
        #balloonMem = 0;                        # Amount of ballooon memory in megabytes; default: 0
        #forwardPorts = [];                     # Port forwarding; default: []
        #devices = [];                          # PCI devices to pass down to guest
        #kernelParams = [];                     # Kernel params to include
        #storeOnDisk = false;                   # Use separate nix store from host
        graphics.enable = machine.vm.graphics;  # Enable local graphics in a window

        # Create the interface before starting the MicroVM
        # sudo ip tuntap add $IFACE_NAME mode tap user $USER
        interfaces = [ {
          # [Macvtap](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#macvtap)
          type = "macvtap";                     # Part of Macvtap
          macvtap.mode = "bridge";              # Macvtap mode
          macvtap.link = machine.macvtap.host;  # Host NIC
          id = machine.hostname;                # i.e. vm-prod1
          mac = "02:00:00:00:00:01";            # Locally administered MACs use '02' prefix
        }];

  #      # Need a volume or VM data won't be persisted
  #      volumes = [
  #        # Preserve appliation data
  #        {
  #          image = "${machine_dir}/var.img";  # Path to the image on the host
  #          mountPoint = "/var";               # Mount point inside the guest
  #          size = 256;
  #        }
  #
  #        # Preserve configuration and passwords
  #        {
  #          image = "${machine_dir}/etc.img";  # Path to the image on the host
  #          mountPoint = "/etc";               # Mount point inside the guest
  #          size = 256;
  #        }
  #      ];

        # Sharing the host /nix/store will save a lot of space
        shares = [ {
          #proto = "virtiofs";                  # Requires the host run the virtiofsd service
          proto = "9p";                         # Built in QEMU share driver, can't use with systemd service
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        } ];
      };
    }

    # Optional SPICE configuration
    (lib.mkIf machine.vm.spice {
      microvm.qemu.extraArgs = [
        "-vga" "qxl"
        "-spice" "port=${toString machine.vm.spicePort},disable-ticketing=on"
        "-device" "virtio-serial"
        "-device" "virtio-keyboard"
        "-chardev" "spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device" "virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];

      # Open up the firewall for machine.vm.spicePort
      networking.firewall.allowedTCPPorts = [ machine.vm.spicePort ];
    })
  ];
}
