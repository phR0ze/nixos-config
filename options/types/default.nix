# Import all the types
#---------------------------------------------------------------------------------------------------
{ lib, ... }: {
let
  userOpts = import ./types/user.nix { inherit lib; };
  typeOpts = import ./types/deployment.nix { inherit lib; };
in
{
  user = userOpts;
  type = typeOpts;
}
