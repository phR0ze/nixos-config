{ lib, pkgs, ... }
{
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

#
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


  # https://github.com/aaronjanse/dotfiles/blob/master/configuration.nix 
  # ------------------------------------------------------------------------------------------------
  services.journald.extraConfig = "MaxRetentionSec=1week";
  programs.adb.enable = true;
  environment.variables.EDITOR = "${pkgs.kakoune}/bin/kak";
  
  networking = {
    hostName = "xps-ajanse";
    networkmanager.enable = true;
    nameservers = pkgs.lib.mkForce [ "193.138.218.74" ]; # mullvad

    iproute2.enable = true;

    wireguard = {
      enable = true;
      interfaces.wg0 = secrets.wireguard;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
      allowedUDPPorts = [ 51820 41641 ];
      trustedInterfaces = [ "wg0" ];
    };
    hosts = {
      "192.168.1.249" = [ "BRW707781875760.local" ];
      "172.31.98.1" = [ "aruba.odyssys.net" ];
      "127.0.0.1" = [ "localhost.dev" "local.metaculus.com" ];
    };
  };

  console = {
    earlySetup = true;
    font = "sun12x22";
    colors = theme.colors16;
  };

  systemd.user.services.xinput-config = {
    description = "configure xinput for xps";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    script = ''
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Accel Speed" 0.55 || true
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Drag Enabled" 0 || true
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SysPS/2 Synaptics TouchPad" "libinput Disable While Typing Enabled" 0 || true
    '';
  };
}
