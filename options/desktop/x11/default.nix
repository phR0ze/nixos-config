# X11 minimal configuration
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
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.services.xserver;

in
{
  imports = [
    ./xft.nix
  ];

  config = lib.mkIf cfg.enable {
    services.xdg.enable = true;

    services.xserver = {
      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick = {
            enable = true;
            draw-user-backgrounds = true;
            theme.name = "Adwaita-dark";
            extraConfig = ''
              enable-hidpi=on
              show-a11y=false
              show-hostname=false
              show-keyboard=false
              clock-format=%a  %b  %d    %I:%M %P
            '';
          };
        };
        autoLogin.enable = args.autologin;
        autoLogin.user = args.username;
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

    services.x11vnc.enable = true;        # Enable the x11vnc server

    environment.systemPackages = with pkgs; [
      xclip                               # Required for neovim to copy paster to/from other apps
      xorg.xkill                          # Kill for X windows instances
      xorg.xrdb                           # X server resource database utility
      xorg.xdpyinfo                       # Display information utility for X

      # Themes, icons and backgrounds
      arc-theme                           # Flat theme with transparent elements for GTK 3 and GTK 2
      arc-kde-theme                       # A port of the arc theme for Plasma
      paper-icon-theme                    # Modern icon theme designed around bold colors
      numix-cursor-theme                  # Numix cursor theme
    ];
  };
}
