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
    libinput.enable = true;

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

  environment.systemPackages = with pkgs; [

   # git                           # The fast distributed version control system
  ];
}

# vim:set ts=2:sw=2:sts=2
