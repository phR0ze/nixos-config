# Immich

Self-hosted photo and video management. Backs up, organizes, and serves media from your own server.

## Configuration Notes

- Listens on port `2283` (default), bound to `0.0.0.0`
- Firewall opened automatically via `openFirewall = true`
- The `immich` user is added to `video` and `render` groups for hardware-accelerated transcoding
- Media stored at `/var/lib/immich` by default; override with `mediaLocation`
- Hardware acceleration devices: set `accelerationDevices = null` for all, or restrict to e.g. `/dev/dri/renderD128`
