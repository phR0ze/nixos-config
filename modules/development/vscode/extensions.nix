# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }:
{
  programs.vscode.extensions = with pkgs.vscode-extensions; [

    # General extensions
    # ----------------------------------------------------------------------------------------
    tamasfe.even-better-toml    # Even Better TOML
    #anseki.vscode-color         # GUI color picker to generate color codes

    golang.go

    # Rust extensions
    # ----------------------------------------------------------------------------------------
    rust-lang.rust-analyzer     # Rust language support, code completion, go to definition etc...
    vadimcn.vscode-lldb         # A native debugger powered by LLDB for C++, Rust and other compiled languages
    serayuzgur.crates           # 

#  ] ++ pkgs.vscode-utils.extensionsFromVsCodeMarketplce [

  ];
}
