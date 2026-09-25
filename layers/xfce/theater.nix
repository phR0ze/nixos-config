# theater.nix provides a full XFCE desktop tuned for a media/theater system
#
# ### Dependencies
# - `xfce.desktop` gets enabled for the full desktop environment
#
# ### Features
# - Desktop with additional media apps/configs
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.layers.xfce.theater;
in
{
  options = {
    layers.xfce.theater = {
      enable = lib.mkEnableOption "Enable the xfce theater layer";
      lowMemory = lib.mkEnableOption "Enable the low memory configuration";
    };
  };

  config = lib.mkMerge [

    (lib.mkIf (cfg.enable) {

      # Desktop dependency with passed along configuration
      layers.xfce.desktop = {
        enable = true;
        lowMemory = lib.mkIf cfg.lowMemory true;
      };

      host.type.theater = true;

      # High dpi settings
      system.x11.xft.dpi = 120; # 25% higher recommended by Arch Linux
      system.xfce.panel.taskbar.size = 36;
      system.xfce.panel.taskbar.iconSize = 32;
      system.xfce.panel.launcher.size = 52;

      # Display configuration
      layers.xfce.base.resolution = { x = 1920; y = 1080; };
      system.xfce.displays.connectingDisplay = 0;

      # Configure theater system background
      system.xfce.desktop.background = "${pkgs.desktop-assets}/share/backgrounds/theater_curtains1.jpg";

      # Add additional theater package
      environment.systemPackages = [
        # pkgs.
      ];
    })
  ];
}
