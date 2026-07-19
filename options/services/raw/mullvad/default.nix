# Mullvad VPN service
#
# ### Description
# Mullvad offers anonymous registration. They don't require your personal information to create an 
# Mullvad is a privacy focused VPN provider. They offer anonymous registration via a generated
# account number. With the anonymous account you can then use a voucher to pay for VPN time
# anonymously as well.
#
# ### Using mullvad GUI app
# Enable with `services.raw.mullvad.gui.enable` to run the official Mullvad daemon and GUI app,
# routing the entire system's traffic over the VPN.
# 1. Ensure the daemon is running `sudo systemctl status mullvad-daemon`
# 2. Login to your account with your auto generated account number
# 3. Configure using [Mullvad config guide](https://github.com/phR0ze/tech-docs/tree/main/src/networking/vpns/mullvad)
#
# ### Using vopono
# Vopono allows for routing specific applications over the VPN while keeping the rest of the system
# running over the standard LAN.
#
# This declaratively deploys `~/.config/vopono/config.toml` with your default provider, server,
# protocol and firewall settings. Note that `config.toml` only holds non-secret defaults.
# 1. Run `vopono sync --protocol wireguard mullvad`
# 2. Enter your mullvad credentials and answer the port forwarding No
# 3. Restart your service `systemctl --user restart APP-over-vpn`
#
# * Note: you can manually start with `xdg-open "/etc/xdg/autostart/${APP}-over-vpn.desktop"`
# * Service will not be restarted if it fails
# * Requires passwordless sudo access to be able to elevate privileges when needed
# * Validation can be done by using firefox as the app and navigating to https://mullvad.net/en/check
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  nic = config.net.primary.name;
  cfg = config.services.raw.mullvad;
in
{
  options = {
    services.raw.mullvad = {
      enable = lib.mkEnableOption "Configure Mullvad VPN service with Vopono";
      autostart = lib.mkOption {
        description = lib.mdDoc "Autostart VPN on login";
        type = types.bool;
        default = true;
      };
      app = lib.mkOption {
        description = lib.mdDoc "Applications to run over the VPN";
        type = types.str;
        default = "qbittorrent";
      };
      server = lib.mkOption {
        description = lib.mdDoc "VPN server to use";
        type = types.str;
        default = "usa-usslc301";
      };
      firewall = lib.mkOption {
        description = lib.mdDoc "Firewall backend for vopono to use, written into vopono's config.toml";
        type = types.enum [ "IpTables" "NfTables" ];
        default = "IpTables";
      };
      dns = lib.mkOption {
        description = lib.mdDoc "Custom DNS servers for vopono to use, written into vopono's config.toml";
        type = types.listOf types.str;
        default = [ ];
      };

      # Used only for the upstream Mullvad GUI a separate app from Vopono
      gui = {
        enable = lib.mkEnableOption "Configure the official Mullvad daemon and GUI app";
      };
    };
  };

  config = lib.mkMerge [

    # Install the official Mullvad daemon and GUI app
    (lib.mkIf cfg.gui.enable {
      services.mullvad-vpn.enable = true;

      environment.systemPackages = [
        pkgs.mullvad-vpn            # Mullvad GUI
        pkgs.wireguard-tools        # Wireguard VPN tooling
        pkgs.iptables               # Low level firewall tools
      ];
    })

    # Install the supporting software
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        pkgs.vopono                 # Network namespace automation
        pkgs.iptables               # Low level firewall tools
        pkgs.wireguard-tools        # Wireguard VPN tooling
      ];

      # Required for WireGuard's fwmark-based policy routing (e.g. used by vopono network
      # namespaces) to work correctly. Without this the kernel's reverse-path filter treats
      # return traffic as a martian packet and silently drops it, even though the WireGuard
      # handshake succeeds.
      boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
      boot.kernel.sysctl."net.ipv4.conf.default.src_valid_mark" = 1;
    })

    # Deploy vopono's config.toml with our default provider/server/protocol/firewall settings.
    # Note this only covers non-secret defaults; WireGuard credentials still require a one-time
    # manual `vopono sync --protocol wireguard mullvad` per the module documentation above.
    (lib.mkIf cfg.enable {
      files.user.".config/vopono/config.toml".text = ''
        provider = "Mullvad"
        protocol = "Wireguard"
        server = "${cfg.server}"
        firewall = "${cfg.firewall}"
      '' + lib.optionalString (cfg.dns != [ ]) ''
        dns = [ ${lib.concatMapStringsSep ", " (ip: "\"${ip}\"") cfg.dns} ]
      '';
    })

    # Configure to autostart after login
    # Creates `/etc/xdg/autostart/APP-over-vpn.desktop`
    (lib.mkIf (cfg.enable && cfg.autostart) {
      environment.etc."xdg/autostart/${cfg.app}-over-vpn.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Terminal=true
        Exec=${pkgs.writeScript "${cfg.app}-over-vpn" ''
          #!${pkgs.runtimeShell}
          if [[ -e "$HOME/.config/vopono" ]]; then
            vopono exec --interface ${nic} --provider mullvad --server ${cfg.server} --protocol wireguard ${cfg.app}
          fi
        ''}
      '';
    })

  ];
}
