# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }:
{
  programs.vscode.extensions = with pkgs.vscode-extensions; [

    # General extensions
    # ----------------------------------------------------------------------------------------
    tamasfe.even-better-toml          # Even Better TOML
    github.copilot                    # Github Copilot uses OpenAI Codex to suggest code
    github.copilot-chat               # Copilot companion extension for chat interface
    golang.go                         # Google official Golang support
    emmanuelbeziat.vscode-great-icons # Awesome icon pack for vscode
    vscodevim.vim                     # Essential vim syntax in vscode

    # Dart extensions
    # ----------------------------------------------------------------------------------------
    dart-code.flutter                 # Official flutter mobile apps support

    # Rust extensions
    # ----------------------------------------------------------------------------------------
    rust-lang.rust-analyzer           # Rust language support, code completion, go to definition etc...
    vadimcn.vscode-lldb               # A native debugger powered by LLDB for C++, Rust and other compiled languages
    serayuzgur.crates                 # Simplify dependency management in Rust

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "vscode-color";          # GUI color picker to generate color codes
      publisher = "anseki";
      version = "0.4.5";
      sha256 = "sha256-xclKrAqa/00xmlfqgIi0cPNyzDI6HFc+bz2kpm4d1AY=";
    }
    {
      name = "vscode-rust-test-adapter"; # Rust test explorer that enables viewing and running rust tests
      publisher = "swellaby";
      version = "0.11.0";
      sha256 = "sha256-IgfcIRF54JXm9l2vVjf7lFJOVSI0CDgDjQT+Hw6FO4Q=";
    }
    {
      name = "vscode-remove-comments"; # Remove all comments from the current selection or the whole doc
      publisher = "rioj7";
      version = "1.8.0";
      sha256 = "sha256-eG5cj1ygGeOI/fttmJJbqFrFNjDUOKbqNOS2Ai+tNYI=";
    }
    {
      name = "vscode-flutter-riverpod-helper"; # Automation to write Riverpod and Freezed classes
      publisher = "evils";
      version = "0.1.10";
      sha256 = "sha256-eG5cj1ygGeOI/fttmJJbqFrFNjDUOKbqNOS2Ai+tNYI=";
    }
  ];
}
