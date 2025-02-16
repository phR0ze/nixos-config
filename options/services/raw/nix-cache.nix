# Nix Binary Cache configuration
#
# ### References
# - nixpkgs/nixos/modules/services/networking/nix-serve.nix
# - nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
# - https://www.freedesktop.org/software/systemd/man/tmpfiles.d
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.nix-cache.host;
  nixServe = config.services.nix-serve;
in
{
  options = {
    services.raw.nix-cache.host = {
      enable = lib.mkEnableOption "Install and configure Nix Binary Cache";
      virtualHost = lib.mkOption {
        description = lib.mdDoc "Nix serve virtual host";
        type = types.str;
        default = "nix-cache";
      };
      secretKeyFile = lib.mkOption {
        description = lib.mdDoc "Nix serve secret key";
        type = types.str;
        default = "/var/lib/nix-cache/private.dec.pem";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No expiration age specified `-` means it will never be cleaned
    systemd.tmpfiles.rules = [
      "d /var/lib/nix-cache 0750 nix-serve nix-serve -"
      ''f ${cfg.secretKeyFile} ${builtins.readFile (../../../include + cfg.secretKeyFile)} -''
    ];
 
    # Configure nix-serve to serve up the nix store as a binary cache with package signing
    services.nix-serve = {
      enable = true;
      secretKeyFile = cfg.secretKeyFile;
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."${cfg.virtualHost}" = {
        locations."/".proxyPass = "http://${nixServe.bindAddress}:${toString nixServe.port}";
      };
    };
 
    # Open up the firewall for port 80
    networking.firewall.allowedTCPPorts = [
      config.services.nginx.defaultHTTPListenPort
    ];
  };
}
