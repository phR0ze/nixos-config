# Visual Studio Code configuration
#
# ### Details
# - https://nixos.wiki/wiki/VSCodium
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
