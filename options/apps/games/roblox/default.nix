# Roblox via Sober (Flatpak)
{ config, lib, pkgs, ... }:
let
  xfce = config.system.xfce;
  cfg = config.apps.games.roblox;
in
{
  options = {
    apps.games.roblox = {
      enable = lib.mkEnableOption "Install and config roblox";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      apps.system.flatpak = {
        enable = true;
        packages = [{ appId = "org.vinegarhq.Sober"; }];
      };
    })
  ];
}
