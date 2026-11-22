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

  loudnessNode = "jellyfin_loudness";
in
{
  options = {
    apps.media.jellyfin = {
      enable = lib.mkEnableOption "Install and configure Jellyfin client";

      maximized = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Start the Jellyfin desktop client maximized the first time it runs. Seeded as initial
          state only: the user's own window changes are saved over it and never overwritten.
        '';
      };

      loudness = {
        enable = lib.mkOption {
          type = types.bool;
          default = config.services.pipewire.enable;
          defaultText = lib.literalExpression "config.services.pipewire.enable";
          description = ''
            Route the client's audio through a PipeWire compressor + limiter sink. Movies keep
            dialog far below music/web loudness to leave headroom for effects, so even at 100% they
            play much quieter than e.g. a browser, worse still with the client's default "Normalize
            downmix" scaling 5.1 down when folding to stereo. This lifts quiet passages without
            clipping loud ones, and only for the client: other apps are untouched. Applies to
            stereo output only, not passthrough bitstreams.
          '';
        };

        threshold = lib.mkOption {
          type = types.numbers.between (-30) 0;
          default = -30;
          description = "Level in dB above which the compressor starts reducing gain.";
        };

        ratio = lib.mkOption {
          type = types.numbers.between 1 20;
          default = 4;
          description = "Compression ratio 1:n above the threshold. Higher is flatter.";
        };

        gain = lib.mkOption {
          type = types.numbers.between 0 24;
          default = 12;
          description = ''
            Makeup gain in dB applied after compression, i.e. how much louder quiet passages get.
            Lower it if loud scenes sound squashed, the limiter keeps it from clipping either way.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      environment.systemPackages = [
        pkgs.jellyfin-ffmpeg          # Jellyfin codecs bundle
        # Crossplatform desktop client, EGL wrapped for VA-API zero-copy on Mesa GPUs. The NVIDIA
        # proprietary driver can't create Qt's xcb_egl context under X11 (aborts with "Failed to
        # initialize graphics backend for OpenGL") and doesn't do VA-API anyway, so use stock there.
        (pkgs.callPackage ./package.nix {
          egl = !config.devices.gpu.nvidia.enable;
          pipewireNode = if cfg.loudness.enable then loudnessNode else null;
        })
      ];
    }

    # Compressor + limiter sink that only the client's audio is routed through, see `loudness`.
    # Loaded into the user's PipeWire daemon; its output follows the default sink.
    (lib.mkIf cfg.loudness.enable (let
      ladspa = "${pkgs.ladspaPlugins}/lib/ladspa";
    in {
      assertions = [
        { assertion = config.services.pipewire.enable;
          message = "apps.media.jellyfin.loudness requires PipeWire (devices.audio.enable)"; }
      ];

      services.pipewire.extraConfig.pipewire."60-jellyfin-loudness"."context.modules" = [{
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Jellyfin Loudness";
          "media.name" = "Jellyfin Loudness";
          "filter.graph" = {
            nodes = [
              { type = "ladspa"; name = "comp"; plugin = "${ladspa}/sc4_1882.so"; label = "sc4";
                control = {
                  "RMS/peak" = 1;                     # RMS detection, follows loudness not spikes
                  "Attack time (ms)" = 10;
                  "Release time (ms)" = 300;
                  "Threshold level (dB)" = cfg.loudness.threshold;
                  "Ratio (1:n)" = cfg.loudness.ratio;
                  "Knee radius (dB)" = 6;
                  "Makeup gain (dB)" = cfg.loudness.gain;
                };
              }
              # Catch the transients the compressor's attack lets through after makeup gain
              { type = "ladspa"; name = "limit"; label = "fastLookaheadLimiter";
                plugin = "${ladspa}/fast_lookahead_limiter_1913.so";
                control = { "Input gain (dB)" = 0; "Limit (dB)" = -1; "Release time (s)" = 0.1; };
              }
            ];
            links = [
              { output = "comp:Left output"; input = "limit:Input 1"; }
              { output = "comp:Right output"; input = "limit:Input 2"; }
            ];
            inputs = [ "comp:Left input" "comp:Right input" ];
            outputs = [ "limit:Output 1" "limit:Output 2" ];
          };
          "audio.channels" = 2;
          "audio.position" = [ "FL" "FR" ];
          "capture.props" = {
            "node.name" = loudnessNode;
            "media.class" = "Audio/Sink";
            "priority.session" = 0;                 # never picked as the default sink
          };
          "playback.props" = {
            "node.name" = "${loudnessNode}.output";
            "node.passive" = true;                  # don't hold the real sink open when idle
          };
        };
      }];
    }))

    (lib.mkIf cfg.maximized {
      files.all.".local/share/jellyfin-desktop/profiles.json".weakCopy = profilesJson;
      files.all."${profileDir}/storage.json".weakCopy = storageJson;
    })
  ]);
}
