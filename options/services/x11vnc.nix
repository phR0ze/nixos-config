# x11vnc configuration
#
# ### Command options
# - rfbauth     VNC password
# - noxdamage   Quicker render (maybe not optimal)
# - nap         If no acitivity, take longer naps
# - many        Keep listening for more connections
# - repeat      X server key auto repeat
# - clear_keys  Clear modifier keys on startup and exit
# - capslock    Don't ignore capslock
# - xkb         Use xkeyboard
# - forever     Keep listening for connection after disconnect
# - loop100     Loop to restart service but wait 100ms
# - auth        X authority file location so vnc also works from display manager (lightdm)
# - display     Which display to show. Even with multiple monitors it's 0
# - no6         Disable IPV6 support
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.x11vnc;
  machine = config.machine;
  vncpass = pkgs.runCommandLocal "x11vnc-passwd" {} ''
    mkdir $out
    ${pkgs.x11vnc}/bin/x11vnc -storepasswd "${machine.user.pass}" "$out/pass"
  '';
in
{
  options = {
    services.x11vnc = {
      enable = lib.mkEnableOption "Install and configure x11vnc";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    networking.firewall.interfaces."${config.networking.primary}".allowedTCPPorts = [ 5900 ];

    environment.systemPackages = with pkgs; [
        x11vnc              # VNC Server
    ];

    systemd.services.x11vnc = {
      enable = true;
      description = "VNC Server for X11";
      requires = [ "display-manager.service" ];
      after = [ "display-manager.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.x11vnc}/bin/x11vnc -rfbauth ${vncpass}/pass -noxdamage -nap -many -repeat -clear_keys -capslock -xkb -forever -loop100 -no6 -auth /var/run/lightdm/root/:0 -display :0";
        ExecStop = "${pkgs.x11vnc}/bin/x11vnc -R stop";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
    };
  };
}
