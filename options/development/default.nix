# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./android.nix
    ./claude-code
    ./flutter.nix
    ./rust.nix
    ./vscode.nix
  ];
}
