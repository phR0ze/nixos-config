# Import all the options
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./android.nix
    ./neovim.nix
    ./rust.nix
    ./vscode.nix
  ];
}
