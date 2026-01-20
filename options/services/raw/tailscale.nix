# Tailscale mesh service
#
# ### Description
# Tailscale is a Zero Trust identity-based connectivity platform that replaces legacy VPN, SASE, and
# PAM and connects remote teams, multi-cloud environments, CI/CD pipelines, Edge & IoT devices and AI
# workloads. Essentially it creates an overlay network composed of your devices that can be reached
# from anywhere in the world.
# - [NixOS Wiki docs](https://nixos.wiki/wiki/Tailscale)
# - [NixOS config](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/tailscale.nix)
#
# ### Deployment notes
# For this to work correctly you'll need some manual setup as well:
# 1. Generate a new key from https://login.tailscale.com/admin/machines/new-linux
# 2. Update the `args.enc.json` with the tailscale secrete as follows
#    "secrets": [
#       {
#         "name": "tailscale",
#         "value": "super-secret-auth-key"
#       }
#     ]
# 3. Optionall run: sudo tailscale cert ${MACHINE_NAME}.${TAILNET_NAME}
# 4. Check service status: sudo systemctl status tailscaled
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.services.raw.tailscale;
  authKey = (f.getSecret config.machine.secrets "tailscale");
in
{
  options = {
    services.raw.tailscale = {
      enable = lib.mkEnableOption "Configure Tailscale mesh service";
      autoStart = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to automatically connect to the tailnet.";
      };
      acceptRoutes = lib.mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Automatically accept routes offered by peers.";
      };
      useRoutingFeatures = lib.mkOption {
        type = types.enum [
          "none"
          "client"
          "server"
          "both"
        ];
        default = "none";
        description = ''
          To use these these features, you will still need to call `sudo tailscale up` with the
          relevant flags like `--advertise-exit-node` and `--exit-node`.
          - When set to `client` or `both`, reverse path filtering will be set to loose instead of strict.
          - When set to `server` or `both`, IP forwarding will be enabled.
        '';
      };
    };
  };
 
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        # Ensure that the authkey exists
        { assertion = (authKey != null); message = "assert authKey: ${authKey}"; }
      ];

      # Configure the tailscale service
      services.tailscale = {
        enable = true;
        openFirewall = true;

        # Don't need tailscale's built in file transfer
        disableTaildrop = true;

        # Don't need or want logging back to the mother ship
        #disableUpstreamLogging = true;

        # Enable routing features
        useRoutingFeatures = cfg.useRoutingFeatures;

        #extraSetFlags = [ ];

        #extraDaemonFlags = [ "TS_DEBUG_DISABLE_IPV6=1" ];

        # Generated a nix store file with the authkey then pass in the path here
        authKeyFile = "${pkgs.runCommandLocal "tailscale-authkey" {} ''
          mkdir $out; echo "${authKey}" > "$out/authkey"
        ''}/authkey";
      };
    })

    # Conditionally override the autostart that is automatically triggered when authKeyFile is set
    # - this allows for starting the service with `sudo systemctl start tailscaled-autoconnect`
    (lib.mkIf (!cfg.autoStart) {
      systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ];
    })

    # Conditionally accept routes from peers in the tailnet
    (lib.mkIf cfg.acceptRoutes {
      services.tailscale.extraUpFlags = [ "--accept-routes" ];
    })
  ];
}
