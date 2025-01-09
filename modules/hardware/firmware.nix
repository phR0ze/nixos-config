# Additional firmware
#
# ### Detail
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # - 'hardware.enableRedistributableFirmware = true;' is just a short cut for the below list
  hardware.firmware = with pkgs; [
    linux-firmware
    intel2200BGFirmware
    rtl8192su-firmware
    rt5677-firmware
    rtl8761b-firmware
    # rtw88-firmware              # linux-firmware now contains this
    zd1211fw
    alsa-firmware
    sof-firmware
    libreelec-dvb-firmware
  ];
}
