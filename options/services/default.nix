{ ... }:
{
  imports = [
    ./nspawn
    ./raw
    ./barrier.nix
    ./cache.nix
    ./nfs.nix
    ./rustdesk.nix
    ./smb.nix
    ./sshd.nix
    ./x11vnc.nix
  ];
}
