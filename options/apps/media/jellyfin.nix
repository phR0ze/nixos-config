# Jellyfin client
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.jellyfin;
in
{
  options = {
    apps.media.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin client";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.jellyfin-ffmpeg          # Jellyfin codecs bundle
      pkgs.jellyfin-media-player    # Crossplatform desktop client
    ];
  };
}
