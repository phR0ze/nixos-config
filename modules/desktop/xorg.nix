# Xorg configuration
#
# ### Details
# - requires a GUI desktop environment
#
# Clock format
# %a  Abbreviated weekday name (Mon, Tue, etc.)
# %A  Full weekday name (Monday, Tuesday, etc.)
# %b  Abbreviated month name (Jan, Feb, etc.)
# %B  Full month name (January, February, etc.)
# %d  Day of month
# %j  Julian day of year
# %m  Month number (01-12)
# %y  Year in century
# %Y  Year with 4 digits
# -------------------------------------------------------------------------------
# %H  Hour (00-23)
# %I  Hour (00-12)
# %M  Minutes (00-59)
# %S  Seconds(00-59)
# %P  AM or PM
# %p  am or pm
# -------------------------------------------------------------------------------
# %D  Date as %m/%d/%y
# %r  Time as %I:%M:%S %p
# %R  Time as %H:%M
# %T  Time as %H:%M:%S
# %Z  Time Zone Name 
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm = {
        enable = true;
        greeters.slick = {
          enable = true;
          draw-user-backgrounds = true;
          extraConfig = ''
            enable-hidpi=on
            show-a11y=false
            show-hostname=false
            show-keyboard=false
            clock-format=%a  %b  %d    %I:%M %P
          '';
        };
      };
    };

            #clock-format=%I:%M:%S

#        greeters.slick = {
#          enable = true;
#          theme = {
#            name = "vimix-dark-ruby";
#            package = pkgs.vimix-gtk-themes.override {
#              themeVariants = ["ruby"];
#              colorVariants = ["dark"];
#              tweaks = ["flat" "grey"];
#            };
#          };
#          iconTheme = {
#            name = "Adwaita";
#            package = pkgs.gnome.adwaita-icon-theme;
#          };
#          extraConfig = ''
#            show-a11y=false
#            clock-format=%H:%M:%S
#          '';
#        };
#      };

      # Conditionally autologin based on install settings
      #autoLogin.enable = args.settings.autologin;
      #autoLogin.user = args.settings.username;

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
