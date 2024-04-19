# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }:
{
  programs.vscode.extensions = with pkgs.vscode-extensions; [

    # General extensions
    # ----------------------------------------------------------------------------------------
    tamasfe.even-better-toml    # Even Better TOML

    golang.go

    # Rust extensions
    # ----------------------------------------------------------------------------------------
    vadimcn.vscode-lldb         # A native debugger powered by LLDB for C++, Rust and other compiled languages

  ] ++ pkgs.vscode-utils.extensionsFromVsCodeMarketplce [

  ];
}
