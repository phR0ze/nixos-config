{ ... }:
{
  imports = [
    ./alerts.nix
    ./crowdsec.nix
    ./sshd
    ./systemd.nix
  ];
}
