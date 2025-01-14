# MicroVM shared configuration

# ### Research
# - nixos-rebuild build-vm is made for testing with limited configuration capabilities i.e. 
#   essentially just build your existing configuration as a vm which is nice but not meant for 
#   declaratively building and hosting your vms.
# - https://github.com/astro/microvm.nix
#   - https://www.youtube.com/watch?v=iGteDsnlCoY
#   - creates systemd units for tap, macvtap, virtiofsd and others
# - qemu introduced the microvm type which removes legacy clutter and is optimized for VirtIO which 
#   now makes it possible to use VMs much like containers only with more isolation and protection
#
# ### Features
# - 
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  machine = config.machine;
in
{
  config = lib.mkMerge [
    {
      microvm = {
        hypervisor = "qemu";                        # "qemu" has 9p built-in!
        vcpu = machine.vm.cores;
        mem = machine.vm.memorySize;
        #graphics.enable = true;

        # Create the interface before starting the MicroVM
        # sudo ip tuntap add $IFACE_NAME mode tap user $USER
  #      interfaces = [ {
  #        type = "tap";
  #        id = machine.hostname;                        # i.e. vm-prod1
  #        mac = "02:00:00:00:00:01";                # Locally administered MACs use '02' prefix
  #      }];

  #      # Need a volume or VM data won't be persisted
  #      volumes = [
  #        # Preserve appliation data
  #        {
  #          image = "${machine_dir}/var.img";       # Path to the image on the host
  #          mountPoint = "/var";                    # Mount point inside the guest
  #          size = 256;
  #        }
  #
  #        # Preserve configuration and passwords
  #        {
  #          image = "${machine_dir}/etc.img";       # Path to the image on the host
  #          mountPoint = "/etc";                    # Mount point inside the guest
  #          size = 256;
  #        }
  #      ];

        # Sharing the host /nix/store will save a lot of space
        shares = [ {
          #proto = "virtiofs";                       # Requires the host run the virtiofsd service
          proto = "9p";                       # Requires the host run the virtiofsd service
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        } ];
      };
    }

    # Optional SPICE configuration
    (lib.mkIf machine.vm.spice {
      microvm.qemu.extraArgs = [
        "-vga qxl"
        "-spice port=${toString machine.vm.spicePort},disable-ticketing=on"
        "-device virtio-serial"
        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
      ];
    })
  ];
}
