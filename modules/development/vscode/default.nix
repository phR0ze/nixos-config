# Visual Studio Code configuration
#---------------------------------------------------------------------------------------------------
{ ... }
{
  imports = [
    ./settings.nix
    ./keybindings.nix
    ./extensions.nix
  ];

  development.vscode.enable = true; 
}
