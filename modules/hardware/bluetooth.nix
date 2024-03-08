# Bluetooth configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    #powerOnBoot = false;      # Have to manually start with this set
  };
  services.blueman.enable = true;
}
