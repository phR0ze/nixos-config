# Private Internet Access

Routes a specific application over PIA's WireGuard VPN using `vopono` network namespaces, while
the rest of the system uses the normal LAN connection.

## Manual Setup

After enabling, run once to configure vopono credentials:

```bash
vopono sync --protocol wireguard PrivateInternetAccess
# Enter PIA credentials; answer "No" to port forwarding
systemctl --user restart <APP>-over-vpn
```

## Configuration Notes

- Default app: `qbittorrent`; set `app` option to change
- Default server: `us-saltlakecity`
- Autostart desktop entry written to `/etc/xdg/autostart/<APP>-over-vpn.desktop`
- Requires passwordless sudo for vopono privilege escalation
- Validate by running firefox as the app and checking `privateinternetaccess.com/pages/whats-my-ip`
