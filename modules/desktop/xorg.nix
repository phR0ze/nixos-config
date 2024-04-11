# Xorg configuration
#
# ### Details
# - requires a GUI desktop environment
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm = {
        enable = true;
        greeters.slick.enable = true;
        greeters.slick.draw-user-backgrounds = true;
        greeters.webkit2.enable = true;
        #greeters.slick = {
        #  enable = true;
        #  theme.name = "Zukitre-dark";
        #};
      };

      # Conditionally autologin based on install settings
      #autoLogin.enable = args.settings.autologin;
      #autoLogin.user = args.settings.username;
    };

    # Arch Linux recommends libinput and Xfce uses it in its settings manager
    libinput = {
      enable = true;
      mouse = {
        accelSpeed = "0.6";
      };
      touchpad = {
        accelSpeed = "1";
        naturalScrolling = true;
      };
    };
  };

  # Disable power management stuff to avoid blanking
  environment.etc."X11/xorg.conf.d/20-dpms.conf".text = ''
    Section "Monitor"
        Identifier "Monitor0"
        Option     "DPMS" "0"
    EndSection
    Section "ServerLayout"
        Identifier "ServerLayout0"
        Option     "OffTime" "0"
        Option     "BlankTime" "0"
        Option     "StandbyTime" "0"
        Option     "SuspendTime" "0"
    EndSection
  '';
}
