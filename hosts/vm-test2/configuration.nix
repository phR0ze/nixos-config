# vm-test2 configuration
#
# ### Features
# - For quick isolated testing where more than one node is needed
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ../../options/virtualisation/qemu/guest.nix
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.hostname = "vm-test2";
    host.type.vm = true;
    host.vm.type.local = true;
    host.resolution = { x = 1920; y = 1080; };
    host.autologin = true;
    host.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to host.id)
  };
}
