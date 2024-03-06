# XDG configuration
#
# ### Details
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
  # Define which well known directories to create
  # xdg-user-dirs-update will run early in the login phase to create them
  # ~/.config/user-dirs.dirs
  environment.etc."xdg/user-dirs.defaults".text = ''
    XDG_DESKTOP_DIR="$HOME/Desktop"
    XDG_DOCUMENTS_DIR="$HOME/Documents"
    XDG_DOWNLOAD_DIR="$HOME/Downloads"
    XDG_MUSIC_DIR="$HOME/Music"
    XDG_PICTURES_DIR="$HOME/Pictures"
    XDG_VIDEOS_DIR="$HOME/Videos"
  '';

  environment.systemPackages = with pkgs; [
    xdg-user-dirs                   # Update XDG user dirs during login
  ];

  xdg = {
    autostart.enable = true;        # Defaults to true
    icons.enable = true;            # Defaults to true
    menus.enable = true;            # Defaults to true
    mime = {
      enable = true;                # Defaults to true
#      addedAssociations = {
#        "application/pdf" = "firefox.desktop";
#         "text/xml" = [
#            "nvim.desktop"
#            "codium.desktop"
#          ];
#      };
    };
    #portal.enable = true;           # ??
    sounds.enable = true;           # Defaults to true
  };
#  xdg.portal = {
#    enable = true;
#    wlr.enable = true;
#    extraPortals = with pkgs; [
#      xdg-desktop-portal-gtk
#      xdg-desktop-portal-wlr
#    ];
#  };
}

# vim:set ts=2:sw=2:sts=2
