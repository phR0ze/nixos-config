# X11 minimal configuration
#
# Clock format
# %a  Abbreviated weekday name (Mon, Tue, etc.)
# %A  Full weekday name (Monday, Tuesday, etc.)
# %b  Abbreviated month name (Jan, Feb, etc.)
# %B  Full month name (January, February, etc.)
# %d  Day of month
# %j  Julian day of year
# %m  Month number (01-12)
# %y  Year in century
# %Y  Year with 4 digits
# -------------------------------------------------------------------------------
# %H  Hour (00-23)
# %I  Hour (00-12)
# %M  Minutes (00-59)
# %S  Seconds(00-59)
# %P  AM or PM
# %p  am or pm
# -------------------------------------------------------------------------------
# %D  Date as %m/%d/%y
# %r  Time as %I:%M:%S %p
# %R  Time as %H:%M
# %T  Time as %H:%M:%S
# %Z  Time Zone Name 
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.system.x11;
in
{
  imports = [
    ./xft.nix
  ];

  options = {
    system.x11 = {
      enable = lib.mkEnableOption "Enable X11";

      autologin = lib.mkEnableOption "Automatically log in after boot";

      autologinUser = lib.mkOption {
        description = lib.mdDoc ''
          Plain (non-secret) user name to automatically log in when `autologin` is set. Leave this
          null to log in the `secret.users."admin"` account instead: its name is only known once
          sops-nix has decrypted it at activation time, so it can't go through nixpkgs'
          eval-time `services.displayManager.autoLogin.user`.
        '';
        type = types.nullOr types.str;
        default = null;
      };

      autolock = {
        enable = lib.mkEnableOption "Enable automatically locking the screen after login";
        exec = lib.mkOption {
          description = lib.mdDoc "Execution command for autolock";
          type = types.path;
          default = "${pkgs.xfce4-session}/bin/xflock4";
        };
      };

      sopsFile = lib.mkOption {
        description = lib.mdDoc ''
          Path to the host's `secrets.enc.yaml`, used to resolve the admin user's name for
          autologin. Required when `autologin` is set and `autologinUser` is null.
        '';
        type = types.nullOr types.path;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      system.xdg.enable = true;

      services = {
        xserver = {
          enable = true;
          displayManager = {
            lightdm = {
              enable = true;
              greeters.slick = {
                enable = true;
                draw-user-backgrounds = true;
                theme.name = "Adwaita-dark";
                extraConfig = ''
                  enable-hidpi=on
                  show-a11y=false
                  show-hostname=false
                  show-keyboard=false
                  clock-format=%a  %b  %d    %I:%M %P
                '';
              };
            };
          };
        };

        # Arch Linux recommends libinput and Xfce uses it in its settings manager
        libinput = {
          enable = true;
          mouse = {
            accelSpeed = "0.6";
          };
          touchpad = {
            accelSpeed = "1";
            naturalScrolling = true;
          };
        };
      };
 
      # Disable power management stuff to avoid blanking
      environment.etc."X11/xorg.conf.d/20-dpms.conf".text = ''
        Section "Monitor"
            Identifier "Monitor0"
            Option     "DPMS" "0"
        EndSection
        Section "ServerLayout"
            Identifier "ServerLayout0"
            Option     "OffTime" "0"
            Option     "BlankTime" "0"
            Option     "StandbyTime" "0"
            Option     "SuspendTime" "0"
        EndSection
      '';

      environment.systemPackages = with pkgs; [
        xclip                               # Required for neovim to copy paster to/from other apps
        xkill                               # Kill for X windows instances
        xrdb                                # X server resource database utility
        xdpyinfo                            # Display information utility for X

        # Themes, icons and backgrounds
        arc-theme                           # Flat theme with transparent elements for GTK 3 and GTK 2
        arc-kde-theme                       # A port of the arc theme for Plasma
        paper-icon-theme                    # Modern icon theme designed around bold colors
        numix-cursor-theme                  # Numix cursor theme
      ];
    }

    # Autologin a plain, non-secret user e.g. the ISO's `nixos` account. Straight through nixpkgs'
    # own option since the name is known at evaluation time.
    # ----------------------------------------------------------------------------------------------
    (lib.mkIf (cfg.autologin && cfg.autologinUser != null) {
      services.displayManager.autoLogin = {
        enable = true;
        user = cfg.autologinUser;
      };
    })

    # Autologin the `secret.users."admin"` account, whose name only exists after activation
    # ----------------------------------------------------------------------------------------------
    # nixpkgs bakes `services.displayManager.autoLogin.user` into the generated lightdm.conf at
    # evaluation time, so it can't carry a name that's still an encrypted secret at that point.
    # Instead render the same keys into a `/etc/lightdm/lightdm.conf.d` drop-in from a sops
    # template: LightDM loads that directory before lightdm.conf, and with nixpkgs' `autoLogin`
    # left disabled lightdm.conf emits no `autologin-*` keys at all, so the drop-in is uncontested.
    # The `lightdm-autologin` PAM stack autologin needs is declared unconditionally by the nixpkgs
    # lightdm module, so nothing else is missing.
    #
    # The template stays at its default `/run/secrets/rendered/...` path and is reached through
    # `environment.etc` rather than being written straight into /etc - that's what reliably creates
    # the `lightdm/lightdm.conf.d` directory, and /etc itself may be a NixOS-managed symlink farm.
    # LightDM runs as root so the template's default root-only mode is fine.
    (lib.mkIf (cfg.autologin && cfg.autologinUser == null) {
      assertions = [
        {
          assertion = cfg.sopsFile != null;
          message = "system.x11.autologin is enabled but neither system.x11.sopsFile nor system.x11.autologinUser is set.";
        }
        {
          assertion = config.services.displayManager.defaultSession != null;
          message = "system.x11.autologin requires services.displayManager.defaultSession to be set.";
        }
      ];

      secret.templates."lightdm-autologin" = {
        content = ''
          [Seat:*]
          autologin-user = ${config.secret.ref."users/admin/name"}
          autologin-user-timeout = 0
          autologin-session = ${config.services.displayManager.defaultSession}
        '';
        secrets."users/admin/name".sopsFile = cfg.sopsFile;

        # Pick up a rotated admin name on the next activation
        restartUnits = [ "display-manager.service" ];
      };

      environment.etc."lightdm/lightdm.conf.d/50-autologin.conf".source =
        config.secret.templates."lightdm-autologin".path;
    })

    # Configure desktop to autolock after login
    (lib.mkIf cfg.autolock.enable {
      environment.etc."xdg/autostart/autolock.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=false
        Exec=bash -c "sleep 5 && ${cfg.autolock.exec}"
      '';
    })
  ]);
}
