# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./android.nix
    ./claude-code
    ./flutter.nix
    ./gh
    ./rust.nix
    ./vscode.nix
    ./zed
  ];
}
