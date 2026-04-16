# Family11 configuration
#
# ### Machine specs
# - ?
#
# ### Features
# - Basic desktop deployment
# - RTL8822BU USB WiFi (0bda:b812) via rtw88_8822bu driver
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/xfce/desktop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    devices.gpu.nvidia = { enable = true; open = true; };

    # RTL8822BU USB WiFi adapter (Realtek 0bda:b812, rtw88_8822bu driver).
    # USB autosuspend causes the adapter to enter low-power states between
    # bursts of activity and fail to wake, producing stalls and disconnects.
    # The udev rule pins power/control to "on" for this specific device.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="b812", TEST=="power/control", ATTR{power/control}="on"
    '';

    # Disable rtw88 deep link power save (LPS-deep). This mode allows the radio
    # to enter an aggressive low-power state during brief idle periods; under
    # bursty traffic it stalls for hundreds of milliseconds waiting to wake back
    # up. NetworkManager power save and USB autosuspend are already disabled
    # above; this is the third layer needed for the RTL8822BU specifically.
    boot.extraModprobeConfig = ''
      options rtw88_core disable_lps_deep=Y
    '';

    apps.dev.claude.enable = true;

    # Pre-generate thumbnails via tumblerd; run: gen-thumbs /mnt/Data
    apps.media.gen-thumbs.enable = true;
  };
}
