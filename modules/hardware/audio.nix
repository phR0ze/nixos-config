# Audio configuration
#
# ### Detail
# - https://nixos.wiki/wiki/PulseAudio
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  hardware.pulseaudio = {
		enable = true;
    support32Bit = true;              # Provide sound for 32bit application
		package = pkgs.pulseaudioFull;    # Provides JACK and Bluetooth support
    #extraConfig = "load-module module-combine-sink";
    #extraConfig = "unload-module module-suspend-on-idle";
#    extraConfig = ''
#      load-module module-udev-detect ignore_dB=1
#      load-module module-detect
#      load-module module-alsa-card device_id="sofhdadsp" tsched=0
#      load-module module-alsa-source device_id="sofhdadsp"
#      load-module module-alsa-sink device_id="sofhdadsp"
#      set-card-profile alsa_card.sofhdadsp output:analog-stereo+input:analog-stereo
#      set-default-sink alsa_output.sofhdadsp.analog-stereo
#      options snd_hda_intel power_save=0
#    '';
  };

  # Additional supporting packages
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs.xfce // pkgs; [
    pavucontrol                       # Xfce default, pulse audio controller
  ];
}
