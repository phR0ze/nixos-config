# Import all the types
#---------------------------------------------------------------------------------------------------
{ lib, ... }:
{
  app = import ./app.nix { inherit lib; };
  nic = import ./nic.nix { inherit lib; };
  drive = import ./drive.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  macvlan = import ./macvlan.nix { inherit lib; };
  machine = import ./machine.nix { inherit lib; };
  vm = import ./vm.nix { inherit lib; };
}
