# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.boot.efi = true;
    host.autologin = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.theater = true;

    devices.gpu.intel.enable = true;
  };
}
