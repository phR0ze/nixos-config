# Theater20 configuration
#
# ### Features
# - Theater focused desktop deployment
# --------------------------------------------------------------------------------------------------
{ lib, ... }:
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

    # The only disk is eMMC, which exposes no S.M.A.R.T. data so smartd would fail to start having
    # found no devices to monitor. Forced so it wins over the xfce layer turning it on.
    services.native.smartd.enable = lib.mkForce false;
  };
}
