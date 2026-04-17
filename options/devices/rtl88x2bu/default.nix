# RTL8822BU USB WiFi device support
#
# ### Purpose
# - Uses the in-kernel rtw88_8822bu driver (rtw88 subsystem)
# - Disables USB autosuspend for the adapter
# - Blacklists the out-of-tree 88x2bu to avoid conflicts if installed
#
# ### History
# - Previously used the morrownr out-of-tree 88x2bu driver, which caused recurring complete
#   dropouts. Switched back to in-kernel rtw88 on kernel 6.18 to re-evaluate; the "failed to
#   get tx report from firmware" stalls seen previously may be fixed in newer kernels.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.devices.rtl88x2bu;
in
{
  options = {
    devices.rtl88x2bu = {
      enable = lib.mkEnableOption "RTL8822BU USB WiFi (in-kernel rtw88_8822bu driver)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # Blacklist the out-of-tree driver if it happens to be present, so it doesn't race with
      # the in-kernel rtw88_8822bu on probe.
      boot.blacklistedKernelModules = [ "88x2bu" ];

      # USB autosuspend causes the adapter to enter low-power states and fail to wake under
      # bursty traffic. Pin power/control to "on" for this specific device (0bda:b812).
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="b812", TEST=="power/control", ATTR{power/control}="on"
      '';
    })
  ];
}
