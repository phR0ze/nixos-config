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
  cfg = config.services.raw.x11vnc;
  host = config.host;
  hasSecrets = host.secrets != null;

  # Legacy eval-time bake (the plaintext password ends up in the Nix store via this derivation's
  # builder script) -- fallback until this host has a `host.secrets` file.
  vncpass = pkgs.runCommandLocal "x11vnc-passwd" {} ''
    mkdir $out
    ${pkgs.x11vnc}/bin/x11vnc -storepasswd "${host.user.pass}" "$out/pass"
  '';

  # Runs at service start instead: reads the plaintext password from
  # config.secret.files."user-password".path (populated by modules/users.nix, decrypted only at
  # activation) and hashes it there, so the plaintext value never appears in a Nix derivation.
  storePasswd = pkgs.writeShellScript "x11vnc-storepasswd" ''
    set -euo pipefail
    ${pkgs.x11vnc}/bin/x11vnc -storepasswd "$(cat ${config.secret.files."user-password".path})" /run/x11vnc/pass
    chmod 600 /run/x11vnc/pass
  '';
in
{
  options = {
    services.raw.x11vnc = {
      enable = lib.mkEnableOption "Install and configure x11vnc";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
        x11vnc              # VNC Server
    ];

    systemd.services.x11vnc = {
      enable = true;
      description = "VNC Server for X11";
      requires = [ "display-manager.service" ];
      after = [ "display-manager.service" ];
      serviceConfig = {
        RuntimeDirectory = lib.mkIf hasSecrets "x11vnc";
        ExecStartPre = lib.mkIf hasSecrets [ "${storePasswd}" ];
        ExecStart =
          if hasSecrets
          then "${pkgs.x11vnc}/bin/x11vnc -rfbauth /run/x11vnc/pass -noxdamage -nap -many -repeat -clear_keys -capslock -xkb -forever -loop100 -no6 -auth /var/run/lightdm/root/:0 -display :0"
          else "${pkgs.x11vnc}/bin/x11vnc -rfbauth ${vncpass}/pass -noxdamage -nap -many -repeat -clear_keys -capslock -xkb -forever -loop100 -no6 -auth /var/run/lightdm/root/:0 -display :0";
        ExecStop = "${pkgs.x11vnc}/bin/x11vnc -R stop";
      };
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
    };

    networking.firewall.interfaces.allowedTCPPorts = [ 5900 ];
  };
}
