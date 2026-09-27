# Minecraft Server

Vanilla Minecraft Java Edition server with configurable seed, game mode, difficulty, and memory.

## Server Interaction

The NixOS module exposes a socket for sending commands:

```bash
# Watch server output
journalctl -u minecraft-server -f

# Send commands (as root)
sudo su
echo "op USERNAME" > /run/minecraft-server.stdin
```

## Configuration Notes

- Data stored at `/var/lib/minecraft`
- `lanOnly = true` (default) skips account validation against minecraft.net (offline mode)
- JVM tuned with G1GC flags for reduced pause times
- `port` (default 25565) is set as `server-port` and opened in the firewall automatically
