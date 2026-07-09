# AdGuard Home

Network-wide DNS-based ad and tracker blocker. Runs as a DNS server that re-routes tracking domains
to a black hole, preventing devices from connecting to them.

## Password Reset

1. Generate a bcrypt hash: `nix-shell -p apacheHttpd --run "htpasswd -nB <USER>"`
2. Trim the `<USER>:` prefix and store only the hash portion

## Configuration Notes

- Binds to the machine's primary NIC IP (`machine.net.nic0.ip`)
- DNS upstream: Cloudflare DoH, Quad9 fallback
- Admin UI and DNS both bind to the LAN IP, not localhost, so correct client IPs are logged
- Data persisted at `/var/lib/adguardhome`
