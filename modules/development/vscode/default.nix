# Visual Studio Code configuration
#
# ### Details
# - https://nixos.wiki/wiki/VSCodium
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.programs.vscode;

  userDir = ".config/Code/User";
  settingsFilePath = "${userDir}/settings.json";
  keybindingsFilePath = "${userDir}/keybindings.json";
  extensionPath = ".vscode/extensions"; # i.e. ~/.vscode/extensions

in
{
  config = {
    imports = [
      ./settings.nix { inherit config lib pkgs settingsFilePath; }
      ./keybindings.nix { inherit config lib pkgs keybindingsFilePath; }
    ];

    programs.vscode.enable = true;        # Visual Studio Code development IDE
  };
}
