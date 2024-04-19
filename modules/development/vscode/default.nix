# Visual Studio Code configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./opts.nix
    ./settings.nix
    ./keybindings.nix
    ./extensions.nix
  ];

  programs.vscode.enable = true;        # Visual Studio Code development IDE
}
