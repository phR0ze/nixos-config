# XFCE full desktop configuration
#
# ### Features
# - Directly installable
# --------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  imports = [
    ./minimal.nix
  ];

  environment.systemPackages = with pkgs; [
    jdk17                             # Needed for: minecraft
    zoom-us                         # Video conferencing application
    #pavucontrol                     

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
  ];

  # plata-theme
  # arc-icon-theme

#  systemd.user.services.dropbox = {
#    description = "Dropbox";
#    wantedBy = [ "default.target" ];
#    environment = {
#      QT_PLUGIN_PATH = "/run/current-system/sw/"
#        + pkgs.qt5.qtbase.qtPluginPrefix;
#      QML2_IMPORT_PATH = "/run/current-system/sw/"
#        + pkgs.qt5.qtbase.qtQmlPrefix;
#    };
#    serviceConfig = {
#      ExecStart = "${pkgs.dropbox.out}/bin/dropbox";
#      ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
#      KillMode = "control-group"; # upstream recommends process
#      Restart = "on-failure";
#      RestartSec = "3";
#      PrivateTmp = true;
#      ProtectSystem = "full";
#      Nice = 10;
#    };
#  };

#  systemd.services.suspend-on-low-battery =
#    let
#      battery-level-sufficient = pkgs.writeShellScriptBin
#        "battery-level-sufficient" ''
#        test "$(cat /sys/class/power_supply/BAT0/status)" != Discharging \
#          || test "$(cat /sys/class/power_supply/BAT0/capacity)" -ge 5
#      '';
#    in
#      {
#        serviceConfig = { Type = "oneshot"; };
#        onFailure = [ "suspend.target" ];
#        script = "${lib.getExe battery-level-sufficient}";
#      };

#  hardware.opengl = {
#    enable = true;
#    extraPackages = with pkgs; [ intel-media-driver vaapiVdpau libvdpau-va-gl ];
#  };
#
#  environment.variables = {
#    VDPAU_DRIVER = "va_gl";
#    LIBVA_DRIVER_NAME = "iHD";
#    MOZ_DISABLE_RDD_SANDBOX = "1";
#  };

#    pavucontrol                   # PulseAudio Volume Control
#    vaapiIntel
#    vaapi-intel-hybrid
#    libva-full
#    libva-utils
#    intel-media-driver
#  ];

  # Optional
  # ------------------------------------------------------------------------------------------------

  # Enable SANE scanners
  # hardware.sane.enable = true; 


    #config = lib.mkAfter ''
    #'';

    # The first element is used as the default resolution
    #resolutions = [
    #  { x = 1920; y = 1080; }
    #];


    # Video drivers to be tried in order until one that supports your card is found
    # Default: modesetting, fbdev
    #videoDrivers = [
    #  "modesetting"
    #  "fbdev"
    #  "nvidia"
    #  "nvidiaLegacy390"
    #  "amdgpu-pro"
    #];

  # ??
#  security.polkit = {
#		enable = true;
#		extraConfig = ''
#			polkit.addRule(function(action, subject) {
#				if (subject.isInGroup("wheel")) {
#					return polkit.Result.YES;
#				}
#			});
#		'';
#	};
#
}
