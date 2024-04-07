# Smplayer options
#
# Adapted from https://gitlab.archlinux.org/archlinux/packaging/packages/smplayer-themes/-/blob/main/PKGBUILD
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.smplayer;

  smplayer-themes = pkgs.stdenvNoCC.mkDerivation rec {
    name = "smplayer-themes";
    version = "20.11.0";
    src = pkgs.fetchzip {
      url = "https://downloads.sourceforge.net/smplayer/${name}-${version}.tar.bz2";
      #hash = "sha256-uZwCoT5Vh+DFnRJ9LyU2obwnQOcm+ttHyJ00nfWVETI=";
      hash = "sha256-+O1fOL7qh/sHN1tEtIANt/+bEOCsjVmECLDBmSSQmHI=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/smplayer
      cp -r $src/usr/share/smplayer/themes $out/share/smplayer
    '';
  };

in
{
  options = {
    programs.smplayer = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install smplayer";
      };
      ownConfigs = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Overwrite settings every reboot/update";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = with pkgs; [
        smplayer
        smplayer-themes
      ];
    })
  ];
}
