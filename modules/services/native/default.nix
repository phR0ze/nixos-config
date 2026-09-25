# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./alerts.nix
    ./crowdsec.nix
    ./jellyfin.nix
    ./nfs.nix
    ./nix-cache
    ./smb.nix
    ./sshd.nix
    ./systemd.nix
  ];
}
