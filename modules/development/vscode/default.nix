# Visual Studio Code configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./settings.nix
    ./keybindings.nix
    ./extensions.nix
  ];

  apps.dev.vscode.enable = true; 
}
