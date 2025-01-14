# vm-prod1 microvm configuration
# --------------------------------------------------------------------------------------------------
{ inputs, config, pkgs, lib, args, f, ... }: with lib.types;
let
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
  machine_dir = "/var/microvms/${cfg.hostname}";
in
{
  imports = [
    (../../. + "/profiles" + ("/" + _args.profile + ".nix"))
  ];

  options = {
    machine = lib.mkOption {
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args f; });
    };
  };

  config = {
    machine.enable = true;
    services.qemuGuest.enable = true;

    #services.x11vnc.enable = lib.mkForce false;

    microvm = {
      hypervisor = "qemu";                        # "qemu" has 9p built-in!
      vcpu = 2;
      mem = 4 * 1024;
      #graphics.enable = true;

      # Create the interface before starting the MicroVM
      # sudo ip tuntap add $IFACE_NAME mode tap user $USER
#      interfaces = [ {
#        type = "tap";
#        id = cfg.hostname;                        # i.e. vm-prod1
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

#      # SPICE configuration
#      qemu.extraArgs = [
#        "-vga qxl"
#        "-spice port=${toString cfg.vm.spicePort},disable-ticketing=on"
#        "-device virtio-serial"
#        "-chardev spicevmc,id=vdagent,debug=0,name=vdagent"
#        "-device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
#      ];
    };
  };
}
