# vps configuration
#
# ### Features
# - Minimal headless command line system
# - Isolated from shared fleet config/secrets
# - Hardened for public internet consuption
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../modules/virtualisation/qemu/guest.nix
    ../../layers/console/vps.nix
  ];

  config = {
    host.type.vm = true;
    host.vm.type.micro = true;
    host.user.secret = true;
    host.net.dns.force = true;

    # Temp testing location
    sops.age.keyFile = "/tmp/shared/key.txt";

    # Minimal headless VM specs - just enough to run a command line system
    # --------------------------------------------
    virtualisation.qemu.guest = {
      cores = 2;
      memorySize = 2;
      rootDrive.size = 35;
      display.enable = false;
      interfaces = [{
        type = "user";
        id = "vps";
        forwardPorts = [
          { host = 2222; guest = 22; }   # SSH access into the VM from the host
        ];
      }];
    };
  };
}
