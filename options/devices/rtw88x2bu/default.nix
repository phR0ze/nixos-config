# RTL8822BU USB WiFi device support
#
# ### Purpose
# - Replaces the in-kernel rtw88_8822bu with the morrownr out-of-tree driver
# - Blacklists in-kernel rtw88 modules to avoid conflicts
# - Disables USB autosuspend for the adapter
# - Disables driver-internal LPS/IPS power save to prevent 10s TX stalls
#---------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.devices.rtw88x2bu;
in
{
  options = {
    devices.rtw88x2bu = {
      enable = lib.mkEnableOption "RTL8822BU USB WiFi (out-of-tree morrownr/88x2bu driver)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      # Load the out-of-tree 88x2bu driver. It is derived from Realtek's vendor source and handles
      # USB TX flow control correctly, avoiding the 20-30s throughput collapses seen with the
      # in-kernel rtw88_8822bu under sustained load ("failed to get tx report from firmware").
      boot.extraModulePackages = [ (config.boot.kernelPackages.callPackage ./package.nix {}) ];

      # Blacklist the in-kernel rtw88 modules so they don't race with 88x2bu on probe.
      boot.blacklistedKernelModules = [ "rtw88_8822bu" "rtw88_8822b" "rtw88_usb" ];

      # USB autosuspend causes the adapter to enter low-power states and fail to wake under
      # bursty traffic. Pin power/control to "on" for this specific device (0bda:b812).
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="b812", TEST=="power/control", ATTR{power/control}="on"
      '';

      # Disable the driver's internal LPS (Legacy Power Save) and IPS (Inactive Power Save).
      # Under heavy TX load the driver enters LPS and stalls for ~10s until its watchdog fires.
      # rtw_power_mgnt=0 disables LPS entirely; rtw_ips_mode=0 disables IPS.
      boot.extraModprobeConfig = ''
        options 88x2bu rtw_power_mgnt=0 rtw_ips_mode=0 rtw_lps_level=0
      '';
    })
  ];
}
