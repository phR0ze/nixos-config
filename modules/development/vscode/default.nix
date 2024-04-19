# Visual Studio Code configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./opts.nix
    ./settings.nix
    ./keybindings.nix
  ];

  programs.vscode.enable = true;        # Visual Studio Code development IDE
}
