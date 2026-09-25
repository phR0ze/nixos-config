# laptop.nix provides a full XFCE desktop with laptop tooling
#
# ### Dependencies
# - `xfce.standard` gets enabled for the full desktop environment
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

  config = lib.mkIf (cfg.enable) (lib.mkMerge [
    {
      layers.xfce.standard = {
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
    }
  ]);
}
