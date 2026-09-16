# Additional firmware
#
# ### Detail
#---------------------------------------------------------------------------------------------------
{ config, pkgs, lib, ... }:
let
  cfg = config.devices.firmware;
in
{
  options = {
    devices.firmware.enable = lib.mkEnableOption "Configure additional firmware";
  };

  config = lib.mkIf (cfg.enable) {

    hardware.firmware = with pkgs; [
      linux-firmware
      ipw2200-firmware
      rtl8192su-firmware
      rt5677-firmware
      rtl8761b-firmware
      # rtw88-firmware              # linux-firmware now contains this
      zd1211fw
      alsa-firmware
      sof-firmware
      libreelec-dvb-firmware
    ];
  };
}
