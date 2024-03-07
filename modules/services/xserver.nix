# Xserver configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  services.xserver = {
    enable = true;
    desktopManager = {
      xterm.enable = false;
    };
    displayManager = {
      lightdm.enable = true;

      # Conditionally autologin based on install settings
      autoLogin = {
        enable = args.settings.autologin;
        user = args.settings.username;
      }; 
    };

    # Arch Linux recommends libinput and Xfce uses it in its settings manager
    libinput = {
      enable = true;
##      touchpad = {
##        accelSpeed = "0.7";
##        tappingDragLock = false;
##        naturalScrolling = true;
##      };
    };
  };

  # Bluetooth configuration
  # ------------------------------------------------------------------------------------------------
#  hardware.bluetooth = {
#    enable = true;
#    powerOnBoot = true;
#  };
  # services.blueman.enable = true;

  # Sound configuration
  # https://nixos.wiki/wiki/PulseAudio
  # ------------------------------------------------------------------------------------------------
  hardware.pulseaudio = {
		enable = true;
    support32Bit = true;            # Provide sound for 32bit application
		package = pkgs.pulseaudioFull;  # Provides JACK and Bluetooth support
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

  # Logind configuration
  # On logout and shutdown kill all users process immediately for fast shutdown
  # ------------------------------------------------------------------------------------------------
  services.logind.extraConfig = ''
    KillUserProcesses=yes
    UserStopDelaySec=0
  '';

  # Printing configuration
  # ------------------------------------------------------------------------------------------------
  services.printing = {
    enable = true;
    browsing = true;
    # drivers = [ pkgs.gutenprint ];
  };

  # Other services
  # ------------------------------------------------------------------------------------------------
  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem
  services.tumbler.enable = true;
  services.timesyncd.enable = true;
}

# vim:set ts=2:sw=2:sts=2
