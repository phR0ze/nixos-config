# Import all the types
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  ip = import ./ip.nix { inherit lib; };
  dns = import ./dns.nix { inherit lib; };
  nic = import ./nic.nix { inherit lib; };
  drive = import ./drive.nix { inherit lib; };
  smb = import ./smb.nix { inherit lib; };
  service = import ./service.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  machine = import ./machine.nix { inherit lib; };
}
