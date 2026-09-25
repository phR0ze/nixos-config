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
# Set services.native.nix-cache.client.enable = true; then run the examples above
# --------------------------------------------------------------------------------------------------
{ config, lib, ... }: with lib.types;
let
  cfg = config.services.native.nix-cache;
in
{
  options = {
    services.native.nix-cache = {
      client = {
        enable = lib.mkEnableOption "Enable the custom binary cache substituter";

        ip = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "IP address of the custom binary cache host.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 5000;
          description = "Port of the custom binary cache host.";
        };

        publicKeyFile = lib.mkOption {
          description = lib.mdDoc ''
            Nix binary cache public key used for client configuration. Public by definition, so
            this stays a plaintext file read at evaluation time (see modules/system/env/nix.nix).
          '';
          type = types.path;
          default = ./include/public.pem;
        };
      };

      host = {
        enable = lib.mkEnableOption "Install and configure Nix Binary Cache";

        bindAddress = lib.mkOption {
          description = lib.mdDoc "IP address where harmonia will bind its listening socket";
          type = types.str;
          default = "0.0.0.0";
        };

        port = lib.mkOption {
          description = lib.mdDoc "Port number where harmonia will listen on";
          type = types.port;
          default = 5000;
        };

        secretKeyFile = lib.mkOption {
          description = lib.mdDoc ''
            sops-encrypted (binary format) Nix binary cache signing key. Decrypted by nix-weave/
            sops-nix at activation time straight to /run/secrets - never staged into git or the
            Nix store. Re-encrypt a new key with `sops --encrypt` after generating it, see the
            README in this directory.
          '';
          type = types.path;
          default = ./include/private.enc.pem;
        };
      };
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.client.enable {
      nix.settings = {
        # Add custom binary caches
        # - https://cache.nixos.org is added by default
        substituters = lib.mkBefore [ "http://${cfg.client.ip}:${toString cfg.client.port}" ];

        # Signing keys for custom substituters
        trusted-public-keys = [ "${(builtins.readFile cfg.client.publicKeyFile)}" ];

        # The custom cache host runs a lot besides the binary cache server (Jellyfin, VMs, containers)
        # and can stall under load. Fail fast against it instead of the 300s default so we fall
        # through to cache.nixos.org or a local build quickly rather than hanging for tens of minutes.
        connect-timeout = lib.mkDefault 5;
        stalled-download-timeout = lib.mkDefault 30;
      };
    })


    (lib.mkIf cfg.host.enable {
      # Decrypted at activation e.g. /run/secrets/nix-cache/secretKey
      secret.files."nix-cache/secretKey" = {
        sopsFile = cfg.host.secretKeyFile;        # sops encrypted path for the secret
        format = "binary";                        # whole file is the secret so no sops key path
        restartUnits = [ "harmonia.service" ];    # restart units if the secret changes to pick up the new key
      };

      # Configure harmonia to serve up the nix store as a binary cache with package signing
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.secret.files."nix-cache/secretKey".path ];
        settings = {
          bind = "${cfg.host.bindAddress}:${toString cfg.host.port}";
          priority = 30;
        };
      };

      # Unlike nix-serve, harmonia has no openFirewall option
      networking.firewall.allowedTCPPorts = [ cfg.host.port ];
    })
  ];
}
