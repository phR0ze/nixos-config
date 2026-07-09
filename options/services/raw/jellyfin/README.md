# Jellyfin

Free software media server for managing and streaming your media library.

## Configuration Notes

- Firewall opens TCP 8096 (HTTP), 8920 (HTTPS), UDP 1900, 7359 via `openFirewall = true`
- The `jellyfin` user is added to `video`, `render`, and `users` groups for hardware-accelerated transcoding
- Config stored at `/var/lib/jellyfin/config`
- Cache stored at `/var/cache/jellyfin`
