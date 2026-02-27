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

    # Install roblox
    (lib.mkIf cfg.enable {
      apps.system.flatpak = {
        enable = true;
        packages = [{ appId = "org.vinegarhq.Sober"; }];
      };
    })

    # XFCE supporting configuration
    (lib.mkIf (cfg.enable && xfce.enable) {
      system.xdg.menu.itemOverrides = [
        {
          source = pkgs.writeTextFile {
            name = "org.vinegarhq.Sober.desktop";
            text = ''
              [Desktop Entry]
              Name=Roblox
              Exec=flatpak run org.vinegarhq.Sober
              Icon=org.vinegarhq.Sober
              Terminal=false
              Type=Application
              Categories=Games;
              StartupNotify=true
              Comment=Play Roblox via Sober
            '';
          };
          categories = "Games";
        }
      ];
    })
  ];
}
