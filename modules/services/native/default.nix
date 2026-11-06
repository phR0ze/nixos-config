# Options for services that are installed directly on either a physical machine or a virtual machine
# as opposed to a container of some kind.
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./adguardhome
    ./alerts.nix
    ./caddy
    ./collabora
    ./crowdsec.nix
    ./immich
    ./immich-public-proxy
    ./jellyfin.nix
    ./keyd
    ./minecraft
    ./mullvad
    ./nextcloud
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
