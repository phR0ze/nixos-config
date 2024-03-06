# XFCE base configuration
#
# ### Features
# - Directly installable
# - Size: 4504.7 MiB
# --------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ../cli
    ../../modules/xdg.nix
    ../../modules/fonts.nix
    ../../modules/networking/network-manager.nix
  ];

  # Configure sound
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

  # Installs xfce4-power-manager
  powerManagement.enable = true;

  # XFCE configuration
  # ------------------------------------------------------------------------------------------------
  services.xserver = {
    enable = true;
    desktopManager = {
      xfce.enable = true;
      xfce.enableXfwm = true;
      xterm.enable = false;
    };
    displayManager = {
      lightdm.enable = true;
      defaultSession = "xfce";

      # Conditionally autologin based on install settings
      autoLogin = {
        enable = args.settings.autologin;
        user = args.settings.username;
      };
    };

    # Xfce uses libinput in its settings manager
    libinput = {
      enable = true;
##      touchpad = {
##        accelSpeed = "0.7";
##        tappingDragLock = false;
##        naturalScrolling = true;
##      };
    };
  };

  environment.xfce.excludePackages = [
  ];

  # Default xfce dbus services
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.printing.enable = true;

  # plata-theme
  # arc-icon-theme

  # Thunar configuration
  # ------------------------------------------------------------------------------------------------
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
  ];
  
  # General applications
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    gnome.gnome-themes-extra          # Xfce default,
    gnome.adwaita-icon-theme          # Xfce default,
    hicolor-icon-theme                # Xfce default,
    tango-icon-theme                  # Xfce default,
    xfce4-icon-theme                  # Xfce default,
    desktop-file-utils                # Xfce default,
    shared-mime-info                  # Xfce default, for update-mime-database
    polkit_gnome                      # Xfce default, polkit authentication agent
    mousepad                          # Xfce default, simple text editor
    parole                            # Xfce default, simple media player
    ristretto                         # Xfce default, simple picture viewer
    xfce4-appfinder                   # Xfce default
    xfce4-notifyd                     # Xfce default
    xfce4-screenshooter               # Xfce default
    xfce4-session                     # Xfce default
    xfce4-settings                    # Xfce default
    xfce4-taskmanager                 # Xfce default
    xfce4-terminal                    # Xfce default

    galculator                        # Simple calculator
    jdk17
    #zoom-us                         # Video conferencing application
    #pavucontrol                     

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))

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

#  hardware.opengl = {
#    enable = true;
#    extraPackages = with pkgs; [ intel-media-driver vaapiVdpau libvdpau-va-gl ];
#  };
#
#  environment.variables = {
#    VDPAU_DRIVER = "va_gl";
#    LIBVA_DRIVER_NAME = "iHD";
#    MOZ_DISABLE_RDD_SANDBOX = "1";
#  };

#    pavucontrol                   # PulseAudio Volume Control
#    vaapiIntel
#    vaapi-intel-hybrid
#    libva-full
#    libva-utils
#    intel-media-driver
#  ];
  ];

  # Optional
  # ------------------------------------------------------------------------------------------------

  # Enable SANE scanners
  # hardware.sane.enable = true; 

  # Enable bluetooth
  # hardware.bluetooth.enable = true;
  # services.blueman.enable = true;










    #config = lib.mkAfter ''
    #'';

    # The first element is used as the default resolution
    #resolutions = [
    #  { x = 1920; y = 1080; }
    #];


    # Video drivers to be tried in order until one that supports your card is found
    # Default: modesetting, fbdev
    #videoDrivers = [
    #  "modesetting"
    #  "fbdev"
    #  "nvidia"
    #  "nvidiaLegacy390"
    #  "amdgpu-pro"
    #];

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

# vim:set ts=2:sw=2:sts=2
