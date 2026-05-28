# Roblox via Sober (Flatpak)
#
{ config, lib, ... }:
let
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
        packages = [{
          appId = "org.vinegarhq.Sober";
          env.PULSE_SERVER = "unix:/run/user/1000/pulse/native";
        }];
      };
    })
  ];
}
