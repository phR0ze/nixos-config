# XDG configuration
#
# ### Details
# - requires a GUI desktop environment
#---------------------------------------------------------------------------------------------------
{ options, config, pkgs, lib, ... }: with lib.types;
let
  xcfg = config.services.xserver;

in
{
  config = lib.mkIf (xcfg.enable) {

    # Define which well known directories to create
    # xdg-user-dirs-update will run early in the login phase to create them
    # ~/.config/user-dirs.dirs
    environment.etc."xdg/user-dirs.defaults".text = ''
      DOWNLOAD=Downloads
      DOCUMENTS=Documents
      PROJECTS=Projects
      SCRIPTS=.local/bin
      MUSIC=Music
      PICTURES=Pictures
      VIDEO=Video
    '';

    environment.systemPackages = with pkgs; [
      xdg-user-dirs                       # Update XDG user dirs during login
      xdg-utils                           # Desktop integration utilities
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
  #            "vscode.desktop"
  #          ];
  #      };
  #      defaultAssociations = {
  #        "application/pdf" = "firefox.desktop";
  #         "text/xml" = [
  #            "nvim.desktop"
  #            "vscode.desktop"
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
  };
}
