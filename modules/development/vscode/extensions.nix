# Visual Studio Code extensions
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  development.vscode.extensions = with pkgs.vscode-extensions; [

    # Native package dependencies
    # ----------------------------------------------------------------------------------------
    rust-lang.rust-analyzer             # Rust language support, code completion, go to definition etc...
    vadimcn.vscode-lldb                 # A native debugger powered by LLDB for C++, Rust and other compiled languages

  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [

    # Rust extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "dependi";                   # Simplify dependency management in Rust
      publisher = "fill-labs";
      version = "0.7.10";
      sha256 = "0pzk8d6zjs91fjys306xv21k6106kqlhnjld1jil762k7gbvdicv";
    }
    {
      name = "vscode-rust-test-adapter";  # Rust test explorer that enables viewing and running rust tests
      publisher = "swellaby";
      version = "0.11.0";
      sha256 = "111vhl71zzh4il1kh21l49alwlllzcvmdbsxyvk9bq3r24hxq1r2";
    }
    {
      name = "vscode-test-explorer";      # Dependency of vscode-rust-test-adapter
      publisher = "hbenl";
      version = "2.22.1";
      sha256 = "1hvzrv7vaxn993imb8h40hch0svg9vrmj7a01pmqwp4hjdkbzxgs";
    }
    {
      name = "test-adapter-converter";    # Dependency of vscode-test-explorer
      publisher = "ms-vscode";
      version = "0.2.0";
      sha256 = "0pj8xglqibjhdpl15r08vylird8vwpb789fyn43r1mh3csiq61xi";
    }

    # Dart extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "dart-code";               # Dart language support and debugger for vscode
      publisher = "dart-code";
      version = "3.99.20241007";
      sha256 = "08xd6lxg8svvidag8qqj1ggprhkv33zj4pv63gyq173277n6ffxp";
    }
    {
      name = "flutter";                 # Official flutter mobile apps support
      publisher = "dart-code";
      version = "3.99.20240930";
      sha256 = "1whly3hwyx2v389llxm6rjds8vfr4n606n64hl79qhrz7w6sc5hb";
    }
    {
      name = "vscode-flutter-riverpod-helper"; # Automation to write Riverpod and Freezed classes
      publisher = "evils";
      version = "0.1.10";
      sha256 = "15lz673mjkfqlpcwx1y00a6q0fj9cpayf2f40iis4h9rq9lx6yiy";
    }

    # Golang extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "go";                      # Google official Golang support
      publisher = "golang";
      version = "0.43.2";
      sha256 = "00bsgmpcg7vakrjcjl6r8jpj7g9pcnnc2f8438mqyxk8hm9lnlic";
    }

    # Nix extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "nix";                     # Nix language support
      publisher = "bbenoist";
      version = "1.0.1";
      sha256 = "0zd0n9f5z1f0ckzfjr38xw2zzmcxg1gjrava7yahg5cvdcw6l35b";
    }

    # General extensions
    # ----------------------------------------------------------------------------------------
    {
      name = "even-better-toml";        # Even Better TOML
      publisher = "tamasfe";
      version = "0.19.2";
      sha256 = "0q9z98i446cc8bw1h1mvrddn3dnpnm2gwmzwv2s3fxdni2ggma14";
    }
    {
      name = "copilot";                 # Github Copilot uses OpenAI Codex to suggest code
      publisher = "github";
      version = "1.236.1144";
      sha256 = "1jffrjp9r04rn79yxmnkpc01i734qxnvcgmh177a4g9gr5p134x9";
    }
    {
      name = "copilot-chat";            # Copilot companion extension for chat interface
      publisher = "github";
      version = "0.22.2024100802";
      sha256 = "012lgmyvyhann898q8mrgnrqpzlkan8w70snnmfnas6m81jsb25r";
    }
    {
      name = "vscode-great-icons";      # Awesome icon pack for vscode
      publisher = "emmanuelbeziat";
      version = "2.1.107";
      sha256 = "1maxva41jgnhw1qi4bvif818rf3g0gbhibkf0ngvyxk0ljrkjsl3";
    }
    {
      name = "remote-containers";       # Open and folder or repo inside a Docker container
      publisher = "ms-vscode-remote";
      version = "0.389.0";
      sha256 = "0ymz5yjrx88a842mpmhfi5pa65cjx94x89j0pklzbsmff6m2949h";
    }
    {
      name = "vim";                     # Essential vim syntax in vscode
      publisher = "vscodevim";
      version = "1.28.1";
      sha256 = "0cwml7z6gj2hi1hr9bzavg4zcij73lap9qgry3biv47pgwzn1gvj";
    }
    {
      name = "vscode-color";            # GUI color picker to generate color codes
      publisher = "anseki";
      version = "0.4.5";
      sha256 = "01nl3mpad91xdwz5f71s6b675wvhnj481sjpk8qlvzws1an4mjf5";
    }
    {
      name = "vscode-remove-comments";  # Remove all comments from the current selection or the whole doc
      publisher = "rioj7";
      version = "1.9.0";
      sha256 = "1vbwv18i8s5f59x6jm7jjmmkvw24887dyyw59m8g8digwr0ippfy";
    }
    {
      name = "github-markdown-preview"; # Markdown extension pack to match Github rendering
      publisher = "bierner";
      version = "0.3.0";
      sha256 = "124vsg5jxa90j3mssxi18nb3wn6fji6b0mnnkasa89rgx3jfb5pf";
    }
  ];
}
