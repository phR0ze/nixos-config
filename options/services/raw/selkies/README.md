# Selkies

Web-based game streaming over GStreamer. Streams an X11 session to a browser client.

## Configuration Notes

- Custom package pulled from `packages/selkies`
- Enabling selkies forces `apps.network.rustdesk.enable = false` (they conflict)
- Service definition is currently WIP (commented out in `default.nix`)
