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
    rust-lang.rust-analyzer     # Rust language support, code completion, go to definition etc...
    vadimcn.vscode-lldb         # A native debugger powered by LLDB for C++, Rust and other compiled languages
    serayuzgur.crates           # 

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "vscode-color";    # GUI color picker to generate color codes
      publisher = "anseki";
      version = "0.4.5";
      sha256 = lib.fakehash;
    }
  ];
}
