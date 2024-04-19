# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }:
{
  programs.vscode.extensions = with pkgs.vscode-marketplace; [
    golang.go
  ];
}
