# SMB / CIFS

Samba client mount configuration. Driven entirely by `machine.smb` args — no option enable flag.

## Configuration Notes

- Activated when `machine.smb.enable = true`
- Mount entries defined in `machine.smb.entries` (list of `{mountPoint, remotePath, user, pass, domain, options, writable, dirMode, fileMode}`)
- Credential files written to `/etc/smb/secrets/<SHARE_NAME>` at build time
- Mounts use `x-systemd.automount` (lazy mount on first access) and `x-systemd.idle-timeout=10min`
- Debugging: `mount -fav` or `findmnt --verify --verbose`
