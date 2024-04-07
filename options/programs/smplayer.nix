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
      hash = "sha256-+O1fOL7qh/sHN1tEtIANt/+bEOCsjVmECLDBmSSQmHI=";
    };

    # Include build time dependencies
    buildInputs = [
      pkgs.optipng
      pkgs.libsForQt5.qt5.qtbase
    ];

    dontWrapQtApps = true;

    # Nix will make the current working directory the root of the unzipped package
    buildPhase = ''
      mkdir $out

      # Fix invalid PNG icons to work with libpng 1.6
      find -name '*.png' -exec optipng -quiet -force -fix {} +

      make PREFIX=$out
    '';

    installPhase = ''
      make PREFIX=$out install
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
