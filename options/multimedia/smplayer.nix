# Smplayer options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.smplayer;

  # Create the smplayer-themes package that is available on other platforms i.e. Arch Linux
  # Adapted from https://gitlab.archlinux.org/archlinux/packaging/packages/smplayer-themes/-/blob/main/PKGBUILD
  smplayer-themes = pkgs.stdenvNoCC.mkDerivation rec {
    name = "smplayer-themes";
    version = "20.11.0";
    src = pkgs.fetchzip {
      url = "https://downloads.sourceforge.net/smplayer/${name}-${version}.tar.bz2";
      hash = "sha256-+O1fOL7qh/sHN1tEtIANt/+bEOCsjVmECLDBmSSQmHI=";
    };

    # Include build time dependencies
    buildInputs = [
      pkgs.optipng                # used below in modifying the pngs
      pkgs.libsForQt5.qt5.qtbase  # used in the makefile to for qt's rcc
    ];

    dontWrapQtApps = true;        # Don't bother with the Qt environment variable overrides

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

  # Create the smplayer settings file with presets
  inifile = lib.mkIf cfg.enable
    (pkgs.writeText "smplayer.ini" ''
      [gui]
      gui=MiniGUI
      iconset=${cfg.theme}
      mouse_wheel_function=${cfg.mouseWheelFunction}
      mouse_double_click_function=fullscreen
      mouse_left_click_function=play_or_pause
      mouse_middle_click_function=mute
      mouse_right_click_function=show_context_menu
    '');

in
{
  options = {
    programs.smplayer = {
      enable = lib.mkEnableOption "Install and configure smplayer";

      theme = lib.mkOption {
        type = types.str;
        default = "Numix-remix";
        description = lib.mdDoc "Smplayer theme to use";
      };
      mouseWheelFunction = lib.mkOption {
        type = types.str;
        default = "4";
        description = lib.mdDoc ''
           2 Media seeking
           4 Volume control
           8 Zoom video
          16 Change speed
        '';
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ smplayer ];

    files.all.".config/smplayer/themes".link = "${smplayer-themes}/share/smplayer/themes";
    files.all.".config/smplayer/smplayer.ini".weakCopy = inifile;
  };
}
