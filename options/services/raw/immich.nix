# Immich
#
# ### Description
# Immich is a Self-hosted photo and video mangement solution to easily back up, organize and manage 
# your photos on your own server. Immich helps you browse, seach and organize your photos and videos 
# with ease, without sacrificing your privacy.
#
# ### References
# 
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
      # Uses port 2283 by default which is what the firewall uses
      services.immich = {
        enable = true;
        port = 2283;          # default: 2283
        host = "0.0.0.0";     # default: locahost
        openFirewall = true;  # default: false

        # If not the default then it will need to be created manually and set for the immich user to 
        # read and write to it. Default: /var/lib/immich
        #mediaLocation = "/mnt/storage/immich";

        # null will give access to all devices
        # you may want to restrict this to a default like /dev/dri/renderD128
        #accelerationDevices = [ "/dev/dri/renderD128" ];
        #accelerationDevices = null;
      };

      environment.systemPackages = [
        #
      ];    

      # Add access to hardware acceleration for transcoding by adding
      # the immich user to render and video groups
      # - https://wiki.nixos.org/wiki/Immich
      users.users.immich.extraGroups = [ "video" "render" ];
    })
  ];
}
