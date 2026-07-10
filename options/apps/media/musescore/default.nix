# MuseScore options
#
# ### Purpose
# - Installs MuseScore (notation editor/PDF export) and the
#   basic-pitch-transcribe script, which transcribes an audio file to MIDI
#   via basic-pitch and renders it to PDF sheet music via MuseScore's CLI
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.media.musescore;
in
{
  options = {
    apps.media.musescore = {
      enable = lib.mkEnableOption "Install MuseScore and the basic-pitch-transcribe script";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      pkgs.musescore
      (pkgs.callPackage ./package.nix {})
    ];
  };
}
