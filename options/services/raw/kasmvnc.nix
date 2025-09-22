# KasmVNC
#
# KasmVNC provides remote web-based access to a Desktop or application. While VNC is in the name, 
# KasmVNC differs from other VNC variants in that it doesn't follow the VNC RFB specification 
# from the RFB specification which defines VNC, in order to support modern technologies and increase 
# security. KasmVNC is accessed by users from any modern browser and does not support legacy VNC 
# viewer applications. KasmVNC uses a modern YAML based configuration at the server and user level, 
# allowing for ease of management.

{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.kasmvnc;
  kasmvnc = pkgs.callPackage ../../../packages/kasmvnc {};
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
