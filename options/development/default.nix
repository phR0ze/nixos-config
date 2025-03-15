# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./android.nix
    ./flutter.nix
    ./neovim.nix
    ./rust.nix
    ./vscode.nix
  ];
}
