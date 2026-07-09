# x11vnc

VNC server for X11. Shares the active X display over the network, including from the LightDM
display manager (before login).

## Configuration Notes

- Listens on TCP port 5900
- Password generated at build time from `machine.user.pass`
- Authenticates against LightDM's X authority at `/var/run/lightdm/root/:0`
- Started as a systemd service after `display-manager.service`
- Notable flags: `-forever` (keep listening after disconnect), `-loop100` (auto-restart with 100ms delay)
