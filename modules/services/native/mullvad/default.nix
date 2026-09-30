# Mullvad VPN service
#
# ### Description
# Mullvad is a privacy focused VPN provider. They offer anonymous registration via a generated
# account number. With the anonymous account you can then use a voucher to pay for VPN time
# anonymously as well.
#
# ### Using mullvad GUI app
# Enable with `services.native.mullvad.gui = true` (alongside `enable`) to run the official Mullvad
# daemon and GUI app, routing the entire system's traffic over the VPN.
# 1. Ensure the daemon is running `sudo systemctl status mullvad-daemon`
# 2. Login to your account with your auto generated account number
# 3. Configure using [Mullvad config guide](https://github.com/phR0ze/tech-docs/tree/main/src/networking/vpns/mullvad)
#
# ### Using vopono
# Vopono allows for routing specific applications over the VPN while keeping the rest of the system
# running over the standard LAN.
#
# 1. Generate a new wireguard public/private key pair
#    nix shell nixpkgs#wireguard-tools -c bash -c 'umask 077; wg genkey | tee privatekey | wg pubkey > publickey'
#
#    1. Login to the [Mullvad Portal](https://mullvad.net/en/account)
#    2. Click the `Devices` option on the left
#    3. Paste in your publickey value generated above into the field and click `upload`
#    4. Copy out and save the generated `IPv4`, `IPv6` values that are displayed
#
# 2. Choose a Mullvad server relay
#    1. Download the relays
#       curl -s https://api.mullvad.net/public/relays/wireguard/v2/ \
#          | jq '.wireguard.relays[] | select(.location | startswith("us-"))'
#       curl -s https://api.mullvad.net/public/relays/wireguard/v2/ | jq '.wireguard.relays[]'
#    2. Collect the relay:
#       * `ipv4_addr_in`
#       * `public_key`
#
# 3. Create the entries in your host's sops encrypted secrets.enc.yaml
#    ```yaml
#    mullvad:
#      address: <IPv4>,<IPv6>
#      publicKey: <YOUR PUBLIC KEY>
#      privateKey: <YOUR PRIVATE KEY>
#      relay:
#        endpoint: <IPv4>:51820
#        publicKey: <RELAY PUBLIC KEY>
#    ```
# 4. Log out and back in to trigger the autostart, or start it manually as noted below
#
# * Note: you can manually start with `xdg-open "/etc/xdg/autostart/mullvad-apps-over-vpn.desktop"`
# * The app will not be restarted if it exits or fails
# * Requires passwordless sudo access to be able to elevate privileges when needed
# * Validation can be done by using brave as an app and navigating to https://mullvad.net/en/check
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  nic = config.devices.network.primary.name;
  cfg = config.services.native.mullvad;
  wgConfig = "mullvad-wg.conf";
  vopono = lib.getExe pkgs.vopono;

  # Start the first app to create the namespace, wait for it to be up, then start the rest which
  # will join the existing namespace rather than racing to create their own
  launcher = pkgs.writeShellScript "mullvad-apps-over-vpn" ''
    ${vopono} exec ${lib.escapeShellArg (lib.head cfg.apps)} &
    ${lib.optionalString (lib.length cfg.apps > 1) ''
    for _ in $(seq 60); do
      [ -n "$(${vopono} list namespaces 2>/dev/null)" ] && break
      sleep 1
    done
    ${lib.concatMapStrings (app: "${vopono} exec ${lib.escapeShellArg app} &\n") (lib.tail cfg.apps)}''}
    wait
  '';
in
{
  options = {
    services.native.mullvad = {
      enable = lib.mkEnableOption "Configure Mullvad VPN service with Vopono";
      autostart = lib.mkOption {
        description = "Autostart VPN on login";
        type = types.bool;
        default = true;
      };
      apps = lib.mkOption {
        description = ''
          Applications to run over the VPN. Each entry is a command line e.g.
          `brave https://mullvad.net/en`. They are launched in order, the first one creating the
          shared VPN network namespace the rest join.
        '';
        type = types.listOf types.str;
        default = [ "qbittorrent" "brave https://mullvad.net/en" ];
      };
      sopsFile = lib.mkOption {
        description = ''
          Path to this host's sops-encrypted secrets file holding the WireGuard private key and
          addresses. Nullable so modules/default.nix can forward `host.sopsFile` here
          unconditionally - required via an assertion when this module is enabled.
        '';
        type = types.nullOr types.path;
        default = null;
      };
      addressSecretRef = lib.mkOption {
        description = ''
          Key path within `sopsFile` holding the comma separated addresses Mullvad assigned to the
          private key's device e.g. `10.64.5.4/32,fc00:eee:bbbe:bb01::1:102/128`
        '';
        type = types.str;
        default = "mullvad/address";
      };
      privateKeySecretRef = lib.mkOption {
        description = "Key path within `sopsFile` holding the WireGuard private key";
        type = types.str;
        default = "mullvad/privateKey";
      };
      relay = {
        endpointSecretRef = lib.mkOption {
          description = ''
            Key path within `sopsFile` holding the IPv4 address and port of the Mullvad WireGuard
            server to connect to e.g. `21.210.100.3:51820`. The port is typically the wireguard
            default 51820
          '';
          type = types.str;
          default = "mullvad/relay/endpoint";
        };
        publicKeySecretRef = lib.mkOption {
          description = ''
            Key path within `sopsFile` holding the public key of the Mullvad WireGuard server to
            connect to
          '';
          type = types.str;
          default = "mullvad/relay/publicKey";
        };
      };
      dns = lib.mkOption {
        description = ''
          DNS servers to use inside the VPN, defaults to Mullvad's in-tunnel DNS server as published
          in Mullvad's help pages. Never empty as the app would otherwise fall back to the host's DNS
          and leak queries outside the VPN.
        '';
        type = types.listOf types.str;
        default = [ "10.64.0.1" ];
      };

      # Used only for the upstream Mullvad GUI, a separate app from Vopono
      gui = lib.mkEnableOption "Also install the official Mullvad daemon and GUI app";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.sopsFile != null;
          message = "services.native.mullvad.sopsFile must be set when services.native.mullvad.enable is enabled";
        }
        {
          assertion = cfg.dns != [ ];
          message = "services.native.mullvad.dns must not be empty, the app's DNS would otherwise leak outside the VPN";
        }
      ];

      environment.systemPackages = [
        pkgs.vopono                # Network namespace automation
        pkgs.wireguard-tools        # Wireguard VPN tooling
      ];

      # Required for WireGuard's fwmark-based policy routing (e.g. used by vopono network
      # namespaces) to work correctly. Without this the kernel's reverse-path filter treats
      # return traffic as a martian packet and silently drops it, even though the WireGuard
      # handshake succeeds.
      boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
      boot.kernel.sysctl."net.ipv4.conf.default.src_valid_mark" = 1;

      # Render the WireGuard config at activation time so the private key never lands in the Nix
      # store. Readable by root only which is fine as vopono elevates before reading it. AllowedIPs
      # must route all traffic as vopono forces the whole network namespace through the tunnel.
      secret.templates.${wgConfig} = {
        filemode = "0400";
        content = ''
          [Interface]
          PrivateKey = ${config.secret.ref.${cfg.privateKeySecretRef}}
          Address = ${config.secret.ref.${cfg.addressSecretRef}}
          DNS = ${lib.concatStringsSep ", " cfg.dns}

          [Peer]
          PublicKey = ${config.secret.ref.${cfg.relay.publicKeySecretRef}}
          AllowedIPs = 0.0.0.0/0, ::0/0
          Endpoint = ${config.secret.ref.${cfg.relay.endpointSecretRef}}
        '';
        secrets.${cfg.privateKeySecretRef}.sopsFile = cfg.sopsFile;
        secrets.${cfg.addressSecretRef}.sopsFile = cfg.sopsFile;
        secrets.${cfg.relay.publicKeySecretRef}.sopsFile = cfg.sopsFile;
        secrets.${cfg.relay.endpointSecretRef}.sopsFile = cfg.sopsFile;
      };

      # Deploy vopono's config.toml pointing at the rendered WireGuard config below. The interface
      # is only written when known, otherwise vopono auto-detects it.
      files.user.".config/vopono/config.toml".copy = ''
        protocol = "Wireguard"
        custom = "${config.secret.templates.${wgConfig}.path}"
        firewall = "NfTables"
      '' + lib.optionalString (nic != "") ''
        interface = "${nic}"
      '';
    }

    # Install the official Mullvad daemon and GUI app
    (lib.mkIf cfg.gui {
      services.mullvad-vpn.enable = true;

      environment.systemPackages = [
        pkgs.mullvad-vpn            # Mullvad GUI
      ];
    })

    # Configure to autostart after login
    # Creates a single `/etc/xdg/autostart/mullvad-apps-over-vpn.desktop` that launches the apps in
    # sequence. Separate autostart entries would race to create the same vopono network namespace
    # and all but one would fail, so the first app creates it and the rest join once it is up.
    (lib.mkIf cfg.autostart {
      assertions = [
        {
          assertion = cfg.apps != [ ] && !(lib.elem "" cfg.apps);
          message = "services.native.mullvad.apps must be set when services.native.mullvad.autostart is enabled";
        }
      ];

      environment.etc."xdg/autostart/mullvad-apps-over-vpn.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=true
        Exec=${launcher}
      '';
    })

  ]);
}
