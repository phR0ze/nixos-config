{ ... }:
{
  imports = [
    ./nspawn
    ./raw
    ./barrier.nix
    ./cache.nix
    ./nfs.nix
    ./smb.nix
    ./sshd.nix
    ./x11vnc.nix
  ];
}
