# Immich
#
# ### Description
# Immich is a Self-hosted photo and video mangement solution to easily back up, organize and manage 
# your photos on your own server. Immich helps you browse, seach and organize your photos and videos 
# with ease, without sacrificing your privacy.
#
# ### Directories
# - /var?
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.raw.immich;
  machine = config.machine;
in
{
  options = {
    services.raw.immich = {
      enable = lib.mkEnableOption "Install and configure Immich server";
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
   
      # Enable Immich server
      services.immich = {
        enable = true;
        openFirewall = true;        # TCP: 8096,8920; UDP: 1900,7359
      };

      environment.systemPackages = [
        pkgs.jellyfin               # Jellyfin core
        pkgs.jellyfin-web           # Jellyfin web client support
        pkgs.jellyfin-ffmpeg        # Jellyfin codecs bundle
      ];    

      # Add access to hardware acceleration for transcoding
      users.users.immich.extraGroups = [ "video" "render" ];
    })
  ];
}
