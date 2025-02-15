# kodi
# A software media player and entertainment hub for digital media
#
# ### References
# - [Kodi data folder](https://kodi.wiki/view/Kodi_data_folder)
#
# ### Data folder
# Kodi purposefully stores all its configuration and data in a single directory for easy backup. This 
# directory is `~/.kodi`
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.kodi;
in
{
  options = {
    apps.media.kodi = {
      enable = lib.mkEnableOption "Install and configure kodi";
      port = lib.mkOption {
        type = types.port;
        default = 8080;
        description = lib.mdDoc "Port to use for remote control.";
      };
      remoteControl = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Enable HTTP remote control.";
      };
      withJellyfin = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable Jellyfin backend add-on.";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.kodi.withPackages (x:
        [ x.youtube ]                                         # Add youtube functionality
        ++ lib.optionals (cfg.withJellyfin) [ x.jellyfin ]    # Add Jellyfin backend for media
      ))
    ];

    # Allow remote control through the firewall
    # View rules with: sudo iptables -S
    networking.firewall.interfaces."${config.networking.primary.id}".allowedTCPPorts =
      lib.optionals (cfg.remoteControl) [ cfg.port ];
  };
}
