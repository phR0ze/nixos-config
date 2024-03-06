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
    ../../modules/networking/network-manager.nix
  ];

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
  };

  # Configure sound
  # https://nixos.wiki/wiki/PulseAudio
  # ------------------------------------------------------------------------------------------------
  hardware.pulseaudio = {
		enable = true;
    support32Bit = true;            # Provide sound for 32bit application
		package = pkgs.pulseaudioFull;  # Provides JACK and Bluetooth support
    #extraConfig = "load-module module-combine-sink";
    #extraConfig = "unload-module module-suspend-on-idle";
  };

  # plata-theme
  # arc-icon-theme

  # Thunar configuration
  # ------------------------------------------------------------------------------------------------
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-volman
    thunar-archive-plugin
  ];

  # General applications
  # ------------------------------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    jdk17

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
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

  # Docker configuration
  # virtualisation.docker.enable = true;










    #config = lib.mkAfter ''
    #'';

    # The first element is used as the default resolution
    #resolutions = [
    #  { x = 1920; y = 1080; }
    #];

    # Arch Linux recommends libinput be enabled
#    libinput = {
#      enable = true;
##      touchpad = {
##        accelSpeed = "0.7";
##        tappingDragLock = false;
##        naturalScrolling = true;
##      };
#    };


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
#  fonts = {
#    fontDir.enable = true;
#    fonts = with pkgs;[
#      corefonts
#      inconsolata
#      terminus_font
#      dejavu_fonts
#      ubuntu_font_family
#      source-code-pro
#      source-sans-pro
#      source-serif-pro
#      roboto-mono
#      roboto
#      overpass
#      libre-baskerville
#      font-awesome
#      julia-mono
#    ];
#  };

}

# vim:set ts=2:sw=2:sts=2
