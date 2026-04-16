# gen-thumbs
#
# ### Purpose
# - Pre-generates freedesktop thumbnails by queuing files directly with tumblerd
#   via D-Bus so Thunar finds them already cached on first open
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.media.gen-thumbs;
in
{
  options = {
    apps.media.gen-thumbs = {
      enable = lib.mkEnableOption "Install gen-thumbs thumbnail pre-generation script";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.callPackage ./package.nix {})
    ];
  };
}
