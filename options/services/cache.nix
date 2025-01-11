# Nix Binary Cache configuration
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.cache;
  virtualhost = "cache";
  decrypted_key_path = "/var/lib/cache/private.dec.pem";
in
{
  options = {
    services.cache = {
      enable = lib.mkEnableOption "Install and configure Nix Binary Cache";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Configure nix-serve to serve up the nix store as a binary cache with package signing
    services.nix-serve = {
      enable = true;
      secretKeyFile = decrypted_key_path;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${virtualhost}" = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
 
    # Open up the firewall for port 80
    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
    ];
  };
}
