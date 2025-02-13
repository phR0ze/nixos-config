# Filezilla options
#
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.network.qbittorrent;

  conf = lib.mkIf cfg.enable (pkgs.writeText "qBittorrent.conf" ''
    [LegalNotice]
    Accepted=${f.boolToStr cfg.acceptedLegalNotice}
  '');
in
{
  options = {
    apps.network.qbittorrent = {
      enable = lib.mkEnableOption "Install and configure qBittorrent";
      acceptedLegalNotice = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Accepts the legal notice";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ qbittorrent ];

    files.all.".config/qBittorrent/qBittorrent.conf".weakCopy = conf;
  };
}
