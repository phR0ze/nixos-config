# laptop.nix provides a full XFCE desktop with laptop tooling
#
# ### Dependencies
# - `xfce.desktop` gets enabled for the full desktop environment
#
# ### Features
# - Desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }:
let
  cfg = config.layers.xfce.laptop;
in
{
  options = {
    layers.xfce.laptop = {
      enable = lib.mkEnableOption "Enable the xfce laptop layer";
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

      apps.network.rustdesk.autostart = false;

      # Slick captive portal solutions for hotels etc...
    #  programs = {
    #    captive-browser = {
    #      enable = true;
    #      interface = config.lib._custom_.wirelessInterface;
    #    };
    #  };

      # Add additional packages
      #environment.systemPackages = with pkgs; [
      #
      #];
    })
  ];
}
