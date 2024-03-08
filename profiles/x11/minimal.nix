# Minimal desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../cli
    ../../modules/hardware/firmware.nix
    ../../modules/hardware/opengl.nix
    ../../modules/xdg.nix
    ../../modules/fonts.nix
    ../../modules/networking/network-manager.nix
  ];

  # Xserver configuration
  #-------------------------------------------------------------------------------------------------
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      lightdm = {
        enable = true;
        #background = "";
        # enso, mini, tiny, slick, mobile, gtk, pantheon
        greeters.slick = {
          enable = true;
          theme.name = "Zukitre-dark";
        };
      };

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

  # Journald configuration
  # ------------------------------------------------------------------------------------------------
  services.journald.extraConfig = ''
    SystemMaxUse=256M
  '';

  # Printing configuration
  # ------------------------------------------------------------------------------------------------
  services.printing = {
    enable = true;
    browsing = true;
    # drivers = [ pkgs.gutenprint ];
  };

  # Other programs and services
  # ------------------------------------------------------------------------------------------------
  programs.file-roller.enable = true;   # Generic Gnome file archive utility needed for Thunar

  services.fwupd.enable = true;         # Firmware update tool for BIOS, etc...
  services.gvfs.enable = true;          # GVfs virtual filesystem
  services.timesyncd.enable = true;

  environment.systemPackages = with pkgs; [

    # System
    desktop-file-utils                  # Command line utilities for working with desktop entries
    filelight                           # View disk usage information
#    gnome-dconf-editor                 # General configuration manager that replaces gconf
    i3lock-color                        # Simple lightweight screen locker
    paprefs                             # Pulse audio server preferences for simultaneous output
  ];

  # plata-theme
  # arc-icon-theme

#  systemd.user.services.dropbox = {
#    description = "Dropbox";
#    wantedBy = [ "default.target" ];
#    environment = {
#      QT_PLUGIN_PATH = "/run/current-system/sw/"
#        + pkgs.qt5.qtbase.qtPluginPrefix;
#      QML2_IMPORT_PATH = "/run/current-system/sw/"
#        + pkgs.qt5.qtbase.qtQmlPrefix;
#    };
#    serviceConfig = {
#      ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
#      ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
#      KillMode = "control-group"; # upstream recommends process
#      Restart = "on-failure";
#      RestartSec = "3";
#      PrivateTmp = true;
#      ProtectSystem = "full";
#      Nice = 10;
#    };
#  };

#  systemd.services.suspend-on-low-battery =
#    let
#      battery-level-sufficient = pkgs.writeShellScriptBin
#        "battery-level-sufficient" ''
#        test "$(cat /sys/class/power_supply/BAT0/status)" != Discharging \
#          || test "$(cat /sys/class/power_supply/BAT0/capacity)" -ge 5
#      '';
#    in
#      {
#        serviceConfig = { Type = "oneshot"; };
#        onFailure = [ "suspend.target" ];
#        script = "${lib.getExe battery-level-sufficient}";
#      };

#
  # ??
#  security.polkit = {
#		enable = true;
#		extraConfig = ''
#			polkit.addRule(function(action, subject) {
#				if (subject.isInGroup("wheel")) {
#					return polkit.Result.YES;
#				}
#			});
#		'';
#	};
#

}
