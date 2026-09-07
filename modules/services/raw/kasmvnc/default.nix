# KasmVNC
#
# KasmVNC provides remote web-based access to a Desktop or application. While VNC is in the name, 
# KasmVNC differs from other VNC variants in that it doesn't follow the VNC RFB specification 
# from the RFB specification which defines VNC, in order to support modern technologies and increase 
# security. KasmVNC is accessed by users from any modern browser and does not support legacy VNC 
# viewer applications. KasmVNC uses a modern YAML based configuration at the server and user level, 
# allowing for ease of management.

{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  host = config.host;
  cfg = config.services.raw.kasmvnc;
  hasSecrets = host.secrets != null;

  kasmvnc = pkgs.callPackage ../../../../packages/kasmvnc {};

  # NOTE: this module has no actual VNC service/systemd unit wired up yet (WIP) -- neither
  # `vncPasswd` below nor a `services.raw.kasmvnc.enable` consumer of it exists downstream, so
  # nothing currently builds or runs this. Kept only as the runtime-safe pattern to wire up
  # (mirroring modules/services/raw/x11vnc) once the service itself is implemented: run
  # `vncpasswd` at service start against the plaintext secret decrypted to
  # config.secret.files."user-password".path (declared once in modules/users.nix) rather than
  # baking the password into a Nix derivation.
  vncPasswd = pkgs.writeShellScript "kasmvnc-passwd" ''
    set -euo pipefail
    cat ${config.secret.files."user-password".path} | ${kasmvnc}/bin/vncpasswd -u "${host.user.name}" -o
  '';
in
{
  options = {
    services.raw.kasmvnc = {
      enable = lib.mkEnableOption "Install and configure kasmvnc server";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Install the actual package
    environment.systemPackages = [ kasmvnc ];

    # Configure firewall exceptions
    #networking.firewall.interfaces.allowedTCPPorts = [ ? ];
  };
}
