# Family15 configuration
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    devices.gpu.intel.enable = true;
    machine.nix.cache.enable = true;
    machine.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    machine.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (ashley/lydia)
    apps.network.rustdesk.secrets = ./secrets.enc.yaml;   # machine-specific (tied to machine.id)

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;
  };
}
