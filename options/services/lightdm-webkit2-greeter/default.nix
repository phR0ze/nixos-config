# lightdm-webkit2-greeter options
#
# Adapted from https://github.com/kira-bruneau/nur-packages/tree/main/pkgs/applications/display-managers/lightdm-webkit2-greeter
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, ... }: with lib.types;
let
  ldmcfg = config.services.xserver.displayManager.lightdm;
  cfg = ldmcfg.greeters.webkit2;

  webkit2GreeterPkg = pkgs.stdenv.mkDerivation rec {
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

    nativeBuildInputs = with pkgs; [ meson ninja pkg-config wrapGAppsHook ];
    buildInputs = with pkgs; [ dbus-glib gtk3 lightdm webkitgtk ];

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

  webkit2GreeterConf = pkgs.writeText "lightdm-webkit2-greeter.conf" ''
    [greeter]
    debug_mode = ${if cfg.debugMode then "true" else "false"}
    detect_theme_errors = ${if cfg.detectThemeErrors then "true" else "false"}
    screensaver_timeout = ${toString cfg.screensaverTimeout}
    secure_mode = ${if cfg.secureMode then "true" else "false"}
    time_format = ${cfg.time.format}
    time_language = ${cfg.time.language}
    webkit_theme = ${cfg.webkitTheme}

    [branding]
    background_images = ${cfg.branding.backgroundImages}
    logo = ${cfg.branding.logo}
    user_image = ${cfg.branding.userImage}
  '';
in
{
  options = {
    services.xserver.displayManager.lightdm.greeters.webkit2 = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Enable the lightdm-webkit2-greeter as the lightdm greeter";
      };

      debugMode = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Show a context menu on right click, which provides access to developer tools.
        '';
      };

      detectThemeErrors = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Provide an option to load a fallback theme when theme errors are detected.
        '';
      };

      screensaverTimeout = mkOption {
        type = types.int;
        default = 300;
        description = lib.mdDoc ''
          Blank the screen after this many seconds of inactivity.
          This only takes effect if launched as a lock-screen (eg. dm-tool lock).
        '';
      };

      secureMode = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          Don't allow themes to make remote http requests.
        '';
      };

      time = {
        format = mkOption {
          type = types.str;
          default = "LT";
          description = lib.mdDoc ''
            A moment.js format string so the greeter can generate localized time for display.
            See http://momentjs.com/docs/#/displaying/format/ for available options.
          '';
        };

        language = mkOption {
          type = types.str;
          default = "auto";
          description = lib.mdDoc ''
            Language to use when displaying the time or "auto" to use the system's language.
          '';
        };
      };

      webkitTheme = mkOption {
        type = types.either types.path (types.enum [ "antergos" "simple" ]);
        default = "antergos";
        example = literalExpression ''
          fetchzip {
            url = "https://github.com/Litarvan/lightdm-webkit-theme-litarvan/releases/download/v3.2.0/lightdm-webkit-theme-litarvan-3.2.0.tar.gz";
            stripRoot = false;
            hash = "sha256-TfNhwM8xVAEWQa5bBdv8WlmE3Q9AkpworEDDGsLbR4I=";
          }
        '';
        description = lib.mdDoc ''
          Path to webkit theme or name of a builtin theme.
        '';
      };

      branding = {
        backgroundImages = mkOption {
          type = types.path;
          default = dirOf ldmcfg.background;
          example = literalExpression "\${pkgs.gnome.gnome-backgrounds}/share/backgrounds/gnome";
          description = lib.mdDoc ''
            Path to directory that contains background images for use by themes.
          '';
        };

        logo = mkOption {
          type = types.path;
          default = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/4f041870efa1a6f0799ef4b32bb7be2cafee7a74/logo/nixos.svg";
            hash = "sha256-E+qpO9SSN44xG5qMEZxBAvO/COPygmn8r50HhgCRDSw=";
          };
          description = lib.mdDoc ''
            Path to logo image for use by greeter themes.
          '';
        };

        userImage = mkOption {
          type = types.path;
          default = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          description = lib.mdDoc ''
            Default user image/avatar. This is used by themes for users that have no .face image.
          '';
        };
      };
    };
  };

  config = mkIf (ldmcfg.enable && cfg.enable) {
    environment.systemPackages = [ webkit2GreeterPkg ];

    services = {
      xserver.displayManager.lightdm = {
        greeters.gtk.enable = false;
        greeter = mkDefault {
          package = webkit2GreeterPkg;
          name = "lightdm-webkit2-greeter";
        };
      };

      # Use Assistive Technologies service
      gnome.at-spi2-core.enable = true;
    };

    environment.etc."lightdm/lightdm-webkit2-greeter.conf".source = webkit2GreeterConf;
  };
}
