# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }:
{
  programs.vscode.extensions = with pkgs.vscode-extensions; [

    # Native package dependencies
    # ----------------------------------------------------------------------------------------
    rust-lang.rust-analyzer             # Rust language support, code completion, go to definition etc...
    vadimcn.vscode-lldb                 # A native debugger powered by LLDB for C++, Rust and other compiled languages

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [

    # Rust extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "crates";                  # Simplify dependency management in Rust
      publisher = "serayuzgur";
      version = "0.6.6";
      sha256 = "sha256-HXoH1IgMLniq0kxHs2snym4rerScu9qCqUaqwEC+O/E=";
    }
    {
      name = "vscode-rust-test-adapter"; # Rust test explorer that enables viewing and running rust tests
      publisher = "swellaby";
      version = "0.11.0";
      sha256 = "sha256-IgfcIRF54JXm9l2vVjf7lFJOVSI0CDgDjQT+Hw6FO4Q=";
    }
    {
      name = "vscode-test-explorer";    # Dependency of vscode-rust-test-adapter
      publisher = "hbenl";
      version = "2.21.1";
      sha256 = "sha256-fHyePd8fYPt7zPHBGiVmd8fRx+IM3/cSBCyiI/C0VAg=";
    }
    {
      name = "test-adapter-converter";  # Dependency of vscode-test-explorer
      publisher = "ms-vscode";
      version = "0.1.9";
      sha256 = "sha256-M53jhAVawk2yCeSrLkWrUit3xbDc0zgCK2snbK+BaSs=";
    }

    # Dart extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "dart-code";               # Dart language support and debugger for vscode
      publisher = "dart-code";
      version = "3.86.0";
      sha256 = "sha256-0B75S2iAXbjN+8BGPQQH5rZDecYCUGeEgFgvpveTklA=";
    }
    {
      name = "flutter";                 # Official flutter mobile apps support
      publisher = "dart-code";
      version = "3.86.0";
      sha256 = "sha256-LRW+U3OhjHIO4PrKiG26h0zCL2wgiTGOmNTLKpsbJFw=";
    }
    {
      name = "vscode-flutter-riverpod-helper"; # Automation to write Riverpod and Freezed classes
      publisher = "evils";
      version = "0.1.10";
      sha256 = "sha256-PnrTacI5QaJjBMQJ59VlSTqAjQLAh87ZpdhNWccxn5Y=";
    }

    # Golang extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "go";                      # Google official Golang support
      publisher = "golang";
      version = "0.41.2";
      sha256 = "sha256-eD/9UBYxf8kmqxuzY+hgAT0bqSiYw/BbDv2gyB63zY0=";
    }

    # Nix extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "nix";                     # Nix language support
      publisher = "bbenoist";
      version = "1.0.1";
      sha256 = "sha256-qwxqOGublQeVP2qrLF94ndX/Be9oZOn+ZMCFX1yyoH0=";
    }

    # General extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "even-better-toml";        # Even Better TOML
      publisher = "tamasfe";
      version = "0.19.2";
      sha256 = "sha256-JKj6noi2dTe02PxX/kS117ZhW8u7Bhj4QowZQiJKP2E=";
    }
    {
      name = "copilot";                 # Github Copilot uses OpenAI Codex to suggest code
      publisher = "github";
      version = "1.180.0";
      sha256 = "sha256-TxqQzJfynmQkS86jnO6TV8MpRIwlkIPen6MtApT8/Uc=";
    }
    {
      name = "copilot-chat";            # Copilot companion extension for chat interface
      publisher = "github";
      version = "0.12.2";
      #sha256 = "sha256-NfVg0Mor6agPrPYuzsNiWgX5DAcSysWaP3GilyXv/S4=";
      sha256 = "sha256-Yysqtp1kXSxrGbFkOkA2hoK2TmWkckgaUgmlAK7qCu8=";
    }
    {
      name = "vscode-great-icons";      # Awesome icon pack for vscode
      publisher = "emmanuelbeziat";
      version = "2.1.104";
      sha256 = "sha256-0F2n9WrQP6dMYTYLAa3iiClHqxpyTvMSGXxlKiucwQA=";
    }
    {
      name = "remote-containers";       # Open and folder or repo inside a Docker container
      publisher = "ms-vscode-remote";
      version = "0.354.0";
      sha256 = "sha256-nx4g73fYTm5L/1s/IHMkiYBlt3v1PobAv6/0VUrlWis=";
    }
    {
      name = "vim";                     # Essential vim syntax in vscode
      publisher = "vscodevim";
      version = "1.27.2";
      sha256 = "sha256-O5G4yhvD2HvKb4Vbvr1v20nMEQq88f5RE+X50bZvr1Q=";
    }
    {
      name = "vscode-color";            # GUI color picker to generate color codes
      publisher = "anseki";
      version = "0.4.5";
      sha256 = "sha256-xclKrAqa/00xmlfqgIi0cPNyzDI6HFc+bz2kpm4d1AY=";
    }
    {
      name = "vscode-remove-comments";  # Remove all comments from the current selection or the whole doc
      publisher = "rioj7";
      version = "1.8.0";
      sha256 = "sha256-eG5cj1ygGeOI/fttmJJbqFrFNjDUOKbqNOS2Ai+tNYI=";
    }
    {
      name = "github-markdown-preview"; # Markdown extension pack to match Github rendering
      publisher = "bierner";
      version = "0.3.0";
      sha256 = "sha256-7pbl5OgvJ6S0mtZWsEyUzlg+lkUhdq3rkCCpLsvTm4g=";
    }
  ];
}
