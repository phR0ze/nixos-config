# Audio configuration
#
# ### Detail
# - https://nixos.wiki/wiki/PulseAudio
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  # Enable the realtime service for scheduling user processes like pipewire for realtime access
  security.rtkit.enable = true;

  # Enable pipewire as the goforward audio solution
  services.pipewire = {
    enable = true;
    alsa.enable = true;               # Enable ALSA support
    pulse.enable = true;              # Enable pulse emulation
  };

  # Additional supporting packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs.xfce // pkgs; [
    pavucontrol                       # Xfce default, pulse audio controller
  ];
}
