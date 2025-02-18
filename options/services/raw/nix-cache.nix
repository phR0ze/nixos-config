# Nix Binary Cache configuration
#
# ### Notes
# This is not secure and only meant to be used on single user system.
#
# ### References
# - nixpkgs/nixos/modules/services/networking/nix-serve.nix
# - nix-store --generate-binary-cache-key key-name secret-key-file public-key-file
# - https://www.freedesktop.org/software/systemd/man/tmpfiles.d
#
# ### Manually curl from another machine to test its available
# $ curl 192.168.1.3:5000/nix-cache-info
# StoreDir: /nix/store
# WantMassQuery: 1
# Priority: 30
#
# ### Verify the signature by manually building on the binary cache host
# $ nix-build '<nixpkgs>' -A pkgs.hello 
# /nix/store/1q8w6gl1ll0mwfkqc3c2yx005s6wwfrl-hello-2.12.1 
#
# $ curl 192.168.1.3:5000/1q8w6gl1ll0mwfkqc3c2yx005s6wwfrl.narinfo
# StorePath: /nix/store/1q8w6gl1ll0mwfkqc3c2yx005s6wwfrl-hello-2.12.1
# ...
# Sig: nix-cache:PR8Vx+mwNYe4t+cbGLe79ir+r1p0u3TdEVjp/4ivo9O7CcugUWv6XBVJ1G3pC0s5EuF+BAQLxb/4yayE1wFLAQ==
#
# ### Configure a client
# Set machine.nix.cache.enable = true; then run the examples above
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.nix-cache.host;
in
{
  options = {
    services.raw.nix-cache.host = {
      enable = lib.mkEnableOption "Install and configure Nix Binary Cache";
      port = lib.mkOption {
        description = lib.mdDoc "Port number where nix-serve will listen on";
        type = types.port;
        default = 5000;
      };
      bindAddress = lib.mkOption {
        description = lib.mdDoc "IP address where nix-serve will bind its listening socket";
        type = types.str;
        default = "0.0.0.0";
      };
      publicKeyFile = lib.mkOption {
        description = lib.mdDoc "Nix serve public key used for client configuration";
        type = types.path;
        default = ../../../include/var/lib/nix-cache/public.pem;
      };
      secretKeyFile = lib.mkOption {
        description = lib.mdDoc "Nix serve secret key local value";
        type = types.path;
        default = ../../../include/var/lib/nix-cache/private.dec.pem;
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.etc."nix-serve-key.pem".text = (builtins.readFile cfg.secretKeyFile);
 
    # Configure nix-serve to serve up the nix store as a binary cache with package signing
    services.nix-serve = {
      enable = true;
      port = cfg.port;
      bindAddress = cfg.bindAddress;
      openFirewall = true;
      secretKeyFile = "/etc/nix-serve-key.pem";
    };
  };
}
