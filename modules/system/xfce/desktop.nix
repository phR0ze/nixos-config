# XFCE Desktop options
#
# Gnerate the ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml configuration file
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  xfce = config.system.desktop.xfce;
  cfg = xfce.desktop;

  # Generate the xfce4-desktop xml settings file based on the given options
  # White space is a little tricky see docs link for more details
  # https://nixos.org/manual/nix/stable/language/values.html?highlight=indent#type-string
  xmlfile = lib.mkIf (xfce.enable)
    (pkgs.writeText "xfce4-desktop.xml" ''
      <?xml version="1.0" encoding="UTF-8"?>

      <channel name="xfce4-desktop" version="1.0">
        <property name="desktop-icons" type="empty">
          <property name="icon-size" type="uint" value="48"/>
          <property name="show-thumbnails" type="bool" value="true"/>
          <property name="file-icons" type="empty">
            <property name="show-home" type="bool" value="${f.boolToStr cfg.showHome}"/>
            <property name="show-trash" type="bool" value="${f.boolToStr cfg.showTrash}"/>
            <property name="show-filesystem" type="bool" value="${f.boolToStr cfg.showFilesystem}"/>
            <property name="show-removable" type="bool" value="${f.boolToStr cfg.showRemovable}"/>
          </property>
        </property>
        <property name="last" type="empty">
          <property name="window-width" type="int" value="${toString cfg.windowWidth}"/>
          <property name="window-height" type="int" value="${toString cfg.windowHeight}"/>
        </property>
      </channel>
    '');
in
{
  options = {
    system.desktop.xfce.desktop = {
      background = lib.mkOption {
        description = "The background image to use for login and wallpaper";
        type = types.either types.path (types.strMatching "^#[0-9]{6}$");
        default = "${pkgs.desktop-assets}/share/backgrounds/sector-8_1600x900.jpg";
      };
      showHome = lib.mkOption {
        description = "Show home icon on desktop";
        type = types.bool;
        default = false;
      };
      showTrash = lib.mkOption {
        description = "Show trash icon on desktop";
        type = types.bool;
        default = false;
      };
      showFilesystem = lib.mkOption {
        description = "Show filesystem icon on desktop";
        type = types.bool;
        default = false;
      };
      showRemovable = lib.mkOption {
        description = "Show removable drives icon on desktop";
        type = types.bool;
        default = false;
      };
      windowWidth = lib.mkOption {
        description = "Desktop settings window width";
        type = types.int;
        default = 885;
      };
      windowHeight = lib.mkOption {
        description = "Desktop settings window height";
        type = types.int;
        default = 710;
      };
    };
  };

  # Install the generated xml file
  config = lib.mkIf xfce.enable {
    # xfdesktop keys backdrops per output connector (`monitoreDP`, `monitorHDMI-A-1`, ...), which
    # varies by driver. Rather than pre-seed every possible name, xfdesktop is rebuilt with the
    # background as its compiled-in fallback, used for any monitor without its own `last-image`.
    nixpkgs.overlays = [ (final: prev: {
      xfdesktop = prev.xfdesktop.overrideAttrs (o: {
        configureFlags = (o.configureFlags or [ ]) ++ [ "--with-default-backdrop-filename=${cfg.background}" ];
      });
    }) ];
    files.all.".config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml".copy = xmlfile;
  };
}
