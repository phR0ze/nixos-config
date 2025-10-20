# Bluetooth configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.devices.bluetooth;
in
{
  options = {
    devices.bluetooth = {
      enable = lib.mkEnableOption "Install and configure Bluetooth";
    };
  };

  config = lib.mkIf (cfg.enable) {
    hardware.bluetooth = {
      enable = true;
      #powerOnBoot = false;      # Have to manually start with this set
    };
    services.blueman.enable = true;
  };
}
