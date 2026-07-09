# NFS

NFS client mount configuration. Driven entirely by `machine.nfs` args — no option enable flag.

## Configuration Notes

- Activated when `machine.nfs.enable = true`
- Mount entries defined in `machine.nfs.entries` (list of `{mountPoint, remotePath, fsType, options}`)
- Entries are translated into `fileSystems` for `/etc/fstab`
- `rpcbind` is enabled as an NFS dependency
