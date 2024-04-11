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
        greeters.slick = {
          enable = true;
          theme.name = "Catppuccin-Frappe-Compact-Mauve-Dark";
          theme.package = pkgs.catppuccin-gtk.override {
            accents = ["mauve"];
            size = "compact";
            variant = "frappe";
            tweaks = ["normal"];
          };

          #iconTheme.name = "Papirus-Dark";
          #iconTheme.package = pkgs.catppuccin-papirus-folders.override {
          #  flavor = "frappe";
          #  accent = "mauve";
          #};
  
          #font.name = "NotoSans Nerd Font Regular";
          #font.package = pkgs.nerdfonts.override {fonts = ["Noto"];};
  
          #cursorTheme.package = pkgs.catppuccin-cursors.frappeDark;
          #cursorTheme.name = "Catppuccin-Frappe-Dark-Cursors";
          #cursorTheme.size = 32;
  
          extraConfig = ''
            background=#ca9ee6
            enable-hidpi=on
          '';
        };
      };
    };

#        greeters.slick.enable = true;
#        greeters.slick.draw-user-backgrounds = true;
#        greeters.slick.extraConfig = ''
#          show-a11y=false
#          show-hostname=false
#          show-keyboard=false
#          clock-format=%H:%M:%S
#        '';

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
