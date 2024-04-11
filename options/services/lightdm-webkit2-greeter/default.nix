# lightdm-webkit2-greeter options
#
# Adapted from https://github.com/kira-bruneau/nur-packages/tree/main/pkgs/applications/display-managers/lightdm-webkit2-greeter
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  ldmcfg = config.services.xserver.displayManager.lightdm;
  cfg = ldmcfg.greeters.webkit2;

  webkit2Greeter = pkgs.stdenvNoCC.mkDerivation rec {
    name = "lightdm-webkit2-greeter";
    version = "2.2.5";
    src = pkgs.fetchFromGitHub {
      owner = "phR0ze";
      repo = "lightdm-webkit2-greeter";
      rev = "refs/tags/${version}";
      hash = "sha256-LY7sVaxBwjojzFa00OkvgR9+TIZuH/WW12UsfpffOIE=";
    };

    outputs = [ "out" "man" ];

    patches = [
      # Support absolute paths in webkit_theme, so custom themes can be selected by a Nix store path
      ./absolute-theme-paths.patch

      # Install default config relative to install prefix
      ./relative-config-install.patch

      # Fixes some of the deprecated functions
      ./fix-deprecated.patch

      # Fix SEGFAULT on startup
      ./fix-double-free.patch

      # Fix loading branding from config into greeter_config.branding JS variable
      ./fix-greeter-config-branding.patch

      # Fix antegros theme crash when hitting escape at password entry
      ./fix-non-click-cancel.patch

      # Fix file requests to symlinks in allowed paths
      ./fix-requesting-symlinks.patch
    ];

    postPatch = "patchShebangs build/utils.sh";

    nativeBuildInputs = [ meson ninja pkg-config wrapGAppsHook ];
    buildInputs = [ dbus-glib gtk3 lightdm webkitgtk ];

    mesonFlags = [
      "-Dwith-theme-dir=${placeholder "out"}/share/lightdm-webkit/themes"
      "-Dwith-desktop-dir=${placeholder "out"}/share/xgreeters"
      "-Dwith-webext-dir=${placeholder "out"}/lib/lightdm-webkit2-greeter"
      "-Dwith-locale-dir=${placeholder "out"}/share/locale"
    ];

    postFixup = ''
      substituteInPlace $out/share/xgreeters/lightdm-webkit2-greeter.desktop \
        --replace "Exec=lightdm-webkit2-greeter" "Exec=$out/bin/lightdm-webkit2-greeter"
    '';

    passthru.xgreeters = linkFarm "lightdm-webkit2-greeter-xgreeters" [{
      path = "${lightdm-webkit2-greeter}/share/xgreeters/lightdm-webkit2-greeter.desktop";
      name = "lightdm-webkit2-greeter.desktop";
    }];

    meta = with lib; {
      description = "A modern, visually appealing greeter for LightDM";
      homepage = "https://github.com/Antergos/web-greeter";
      license = licenses.gpl3Plus;
      maintainers = with maintainers; [ kira-bruneau ];
      platforms = platforms.linux;
      mainProgram = "lightdm-webkit2-greeter";
    };
  };
in
{
  options = {
    services.xserver.displayManager.lightdm.greeters.webkit2 = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install lightdm-webkit2-greeter";
      };
    };
  };

  config = lib.mkIf (lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ webkit2Greeter ];
    #files.all.".config/smplayer/themes".link = "${smplayer-themes}/share/smplayer/themes";
  };
}
