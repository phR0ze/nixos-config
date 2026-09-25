# Jellyfin client
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.media.jellyfin;

  # Jellyfin Media Player keeps its per-profile state under a randomly named profile directory
  # (~/.local/share/jellyfin-desktop/profiles/<32 hex chars>), so there's no fixed path to seed
  # unless we create the profile ourselves. Any directory matching that naming is adopted by the
  # app on first run (ProfileManager::scanProfilesDirectory), and profiles.json names it.
  profileId = "00000000000000000000000000000001";
  profileDir = ".local/share/jellyfin-desktop/profiles/${profileId}";

  profilesJson = builtins.toJSON {
    defaultProfile = profileId;
    profiles = [{ id = profileId; name = "Default"; url = ""; }];
  };

  # Window state lives in the profile's storage.json. `maximized` is the screen-layout independent
  # key that WindowManager::loadGeometry falls back to when it has no saved state for the current
  # screen setup i.e. the out-of-the-box case. `version` must match the app's settings version or
  # it renames the file to storage.json.broken and starts from its own defaults. Note the app only
  # ever clears its per-screen-layout key, not this one, so unmaximizing doesn't stick across
  # restarts - drop the key from the user's own storage.json for that.
  storageJson = builtins.toJSON {
    sections.state.maximized = true;
    version = 7;
  };
in
{
  options = {
    apps.media.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin client";

      maximized = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Start the Jellyfin desktop client maximized the first time it runs. Seeded as initial
          state only: the user's own window changes are saved over it and never overwritten.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.jellyfin-ffmpeg          # Jellyfin codecs bundle
        pkgs.jellyfin-media-player    # Crossplatform desktop client
      ];
    }

    (lib.mkIf cfg.maximized {
      files.all.".local/share/jellyfin-desktop/profiles.json".weakCopy = profilesJson;
      files.all."${profileDir}/storage.json".weakCopy = storageJson;
    })
  ]);
}
