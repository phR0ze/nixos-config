# Import all the types
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  app = import ./app.nix { inherit lib; };
  nic = import ./nic.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  macvlan = import ./macvlan.nix { inherit lib; };
  deployment = import ./deployment.nix { inherit lib; };
}
