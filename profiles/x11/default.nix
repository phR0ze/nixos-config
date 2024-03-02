# Minimal desktop independent X11 configuration
#
# ### Features
# - Directly installable
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ../cli
  ];

  services.xserver = {
    enable = true;
    #config = lib.mkAfter ''
    #'';

    # The first element is used as the default resolution
    #resolutions = [
    #  { x = 1920; y = 1080; }
    #];

    # Arch Linux recommends libinput be enabled
    libinput = {
      enable = true;
#      touchpad = {
#        tappingDragLock = false;
#        naturalScrolling = true;
#      };
    };


    # Video drivers to be tried in order until one that supports your card is found
    # Default: modesetting, fbdev
    #videoDrivers = [
    #  "modesetting"
    #  "fbdev"
    #  "nvidia"
    #  "nvidiaLegacy390"
    #  "amdgpu-pro"
    #];

    # This will be overriden by other options e.g. `displayManager.xfce.enable`
    displayManager.startx.enable = true;
  };

  # Configure sound
  sound.enable = true;
  hardware.pulseaudio = {
		enable = true;
		package = pkgs.pulseaudioFull;
    daemon.config = { flat-volumes = "no"; };
	};

  # ??
  security.polkit = {
		enable = true;
		extraConfig = ''
			polkit.addRule(function(action, subject) {
				if (subject.isInGroup("wheel")) {
					return polkit.Result.YES;
				}
			});
		'';
	};

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs;[
      corefonts
      inconsolata
      terminus_font
      dejavu_fonts
      ubuntu_font_family
      source-code-pro
      source-sans-pro
      source-serif-pro
      roboto-mono
      roboto
      overpass
      libre-baskerville
      font-awesome
      julia-mono
    ];
  };

  environment.systemPackages = with pkgs; [
    pavucontrol                   # PulseAudio Volume Control
    vaapiIntel
    vaapi-intel-hybrid
    libva-full
    libva-utils
    intel-media-driver
  ];
}

# vim:set ts=2:sw=2:sts=2
