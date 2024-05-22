# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./minecraft-server.nix
    ./prismlauncher.nix
    ./protontricks.nix
    ./steam.nix
  ];
}
