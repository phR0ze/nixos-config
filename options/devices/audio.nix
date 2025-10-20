# Audio configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.devices.audio;
in
{
  options = {
    devices.audio = {
      enable = lib.mkEnableOption "Install and configure audio";
    };
  };

  config = lib.mkIf (cfg.enable) {
    # Enable the realtime service for scheduling user processes like pipewire for realtime access
    security.rtkit.enable = true;

    # Enable pipewire as the goforward audio solution
    services.pipewire = {
      enable = true;
      alsa.enable = true;               # Enable ALSA support
      pulse.enable = true;              # Enable pulse emulation
    };

    # Additional supporting packages
    environment.systemPackages = with pkgs.xfce // pkgs; [
      pavucontrol                       # Xfce default, pulse audio controller
    ];
  };
}
