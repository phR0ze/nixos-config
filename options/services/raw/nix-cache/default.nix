# Nix Binary Cache configuration
#
# ### Notes
# This is not secure and only meant to be used on single user system.
#
# Uses harmonia rather than nix-serve: nix-serve shells out to `nix-store` per request and signs
# narinfo synchronously, which stalls badly under concurrent load or host contention. harmonia talks
# to the Nix store directly and handles concurrency far better while speaking the same protocol.
#
# ### References
# - nixpkgs/nixos/modules/services/networking/harmonia.nix
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
        description = lib.mdDoc "Port number where harmonia will listen on";
        type = types.port;
        default = 5000;
      };
      bindAddress = lib.mkOption {
        description = lib.mdDoc "IP address where harmonia will bind its listening socket";
        type = types.str;
        default = "0.0.0.0";
      };
      publicKeyFile = lib.mkOption {
        description = lib.mdDoc "Nix binary cache public key used for client configuration";
        type = types.path;
        default = ../../../../include/var/lib/nix-cache/public.pem;
      };
      secretKeyFile = lib.mkOption {
        description = lib.mdDoc "Nix binary cache secret key local value";
        type = types.path;
        default = ../../../../include/var/lib/nix-cache/private.dec.pem;
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) (
    let
      harmoniaCache = {
        enable = true;
        signKeyPaths = [ cfg.secretKeyFile ];
        settings = {
          bind = "${cfg.bindAddress}:${toString cfg.port}";
          priority = 30;
        };
      };

      # Configure harmonia to serve up the nix store as a binary cache with package signing.
      # harmonia reads the signing key itself via systemd LoadCredential, so no need to also copy it
      # into /etc the way nix-serve required.
      #
      # nixpkgs renamed services.harmonia -> services.harmonia.cache in 26.11. Machines can pin
      # different nixpkgs revisions (e.g. macbook stays on an older T2-patched pin), so pick the
      # attribute path matching the pinned nixpkgs version at eval time -- this must be a plain
      # Nix if/else rather than lib.mkIf, since the module system validates that an option path
      # exists even when its definition is conditionally disabled.
      harmoniaConfig =
        if lib.versionAtLeast pkgs.lib.version "26.11"
        then { services.harmonia.cache = harmoniaCache; }
        else { services.harmonia = harmoniaCache; };
    in
    harmoniaConfig // {
      # Unlike nix-serve, harmonia has no openFirewall option
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    }
  );
}
