# vm-test2 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../options/virtualisation/qemu/guest.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.hostname = "vm-test2";
    machine.type.vm = true;
    machine.vm.type.local = true;
    machine.resolution = { x = 1920; y = 1080; };
    machine.autologin = true;
    machine.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to machine.id)
  };
}
