# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome
    ./alerts.nix
    ./caddy
    ./crowdsec.nix
    ./jellyfin.nix
    ./keyd
    ./minecraft
    ./mullvad
    ./nfs.nix
    ./nix-cache
    ./smartd.nix
    ./smb.nix
    ./sshd.nix
    ./synology-drive-client
    ./systemd.nix
    ./vaultwarden.nix
  ];
}
