# XFCE configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ config, args, ... }:
{
  programs.xfconf.enable = true;

  #environment.etc.""
  #environment.home.""?


  # Development details
  # - https://xfce.readthedocs.io/en/latest/core/xfconf/index.html
  # - https://www.spurint.org/journal/2008/10/xfconf-a-new-configuration-storage-system
  #
  #
  # ### xfconfd
  # - loads configuration from $HOME/.config/xfce4/xfconf if it exists
  # - loads configuration from /etc/xdg/xfce4/xfconf for defaults
  # ------------------------------------------------------------------------------------------------

#  export STARSHIP_CONFIG=${
#    pkgs.writeText "starship.toml"
#    (lib.fileContents ../../include/.config/starship.toml)
#  }

#  xfconf.settings = {
#    xsettings = {
#      "Gdk/WindowScalingFactor" = 2;
#      "Xft/DPI" = 100;
#      "Xfce/LastCustomDPI" = 100;
#    };
#    xfce4-session = {
#      "startup/ssh-agent/enabled" = false;
#      "general/LockCommand" = "${pkgs.lightdm}/bin/dm-tool lock";
#    };
#    xfce4-desktop = {
#      "backdrop/screen0/monitorLVDS-1/workspace0/last-image" =
#        "${pkgs.nixos-artwork.wallpapers.stripes-logo.gnomeFilePath}";
#    };
#  };
}
