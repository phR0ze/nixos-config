# OBS Studio
#
# ### Description
# OBS Studio is free and open-source software for video recording and live streaming.
#
# ### Plugins
# - [Background removal plugin](https://github.com/locaal-ai/obs-backgroundremoval)
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.obs;
in
{
  options = {
    apps.media.obs = {
      enable = lib.mkEnableOption "Install and configure OBS Studio";
      ndi = lib.mkOption {
        description = lib.mdDoc "Install and configure NDI plugin";
        type = types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.wrapOBS {
        plugins = with pkgs.obs-studio-plugins; [
          obs-backgroundremoval                 # Remove or blur the video background
          obs-pipewire-audio-capture            # Capture appliation audio with PipeWire
        ] ++ lib.optionals cfg.ndi [ obs-ndi ]; # Optional NDI support
      })
    ];

    # polkit needs to be enabled so that OBS can access the virtual camera device
    security.polkit.enable = true;
  };
}
