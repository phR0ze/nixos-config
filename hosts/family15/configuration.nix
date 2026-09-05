# Family15 configuration
#
# ### Features
# - Basic desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../layers/bundles/xfce-desktop.nix
  ];

  config = {
    host.type.bootable = true;
    devices.gpu.intel.enable = true;
    host.nix.cache.enable = true;
    host.secrets = ../../secrets.enc.yaml;   # shared default (user.password/passwordHash)
    host.smb.secrets = ./secrets.enc.yaml;   # real per-share passwords (ashley/lydia)

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;
  };
}
