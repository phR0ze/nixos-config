# Zed editor
#
# ### Reference
# - [Zed - NixOS Wiki](https://wiki.nixos.org/wiki/Zed)
# - [Zed Editor - NixPkgs](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ze/zed-editor/package.nix#L341)
# - [Home Manager zed-editor module](https://github.com/nix-community/home-manager/blob/master/modules/programs/zed-editor.nix)
#
# ### Purpose
# - Exposes Zed configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.dev.zed;

  jsonFormat = pkgs.formats.json { };

  configDir = ".config/zed";
  settingsFilePath = "${configDir}/settings.json";
  keymapFilePath = "${configDir}/keymap.json";
  tasksFilePath = "${configDir}/tasks.json";

  mergedSettings = cfg.settings // lib.optionalAttrs (cfg.extensions != []) {
    auto_install_extensions = lib.genAttrs cfg.extensions (_: true);
  };

  zedPackage = if cfg.extraPackages == [] then pkgs.zed-editor
    else pkgs.symlinkJoin {
      name = "zed-editor-wrapped";
      paths = [ pkgs.zed-editor ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/zeditor \
          --prefix PATH : ${lib.makeBinPath cfg.extraPackages}
      '';
    };
in
{
  options = {
    apps.dev.zed = {
      enable = lib.mkEnableOption "Install and configure Zed";

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = {
          vim_mode = true;
          base_keymap = "VSCode";
          ui_font_size = 18;
          buffer_font_size = 15;
          theme = {
            mode = "dark";
            light = "Tokyo Night Storm";
            dark = "Tokyo Night Storm";
          };
          icon_theme = "VSCode Great Icons Theme";
          auto_update = false;
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };
        description = ''
          Configuration written to Zed's {file}`settings.json`.
        '';
      };

      keymaps = lib.mkOption {
        type = jsonFormat.type;
        default = [ ];
        example = lib.literalExpression ''
          [
            {
              context = "Workspace";
              bindings = {
                "ctrl-shift-t" = "workspace::NewTerminal";
              };
            }
          ]
        '';
        description = ''
          Keymaps written to Zed's {file}`keymap.json`.
        '';
      };

      userTasks = lib.mkOption {
        type = jsonFormat.type;
        default = [ ];
        example = lib.literalExpression ''
          [
            {
              label = "build";
              command = "cargo build";
            }
          ]
        '';
        description = ''
          Tasks written to Zed's {file}`tasks.json`.
        '';
      };

      extensions = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "nix"
          "toml"
          "just"
          "helm"
          "dockerfile"
          "vscode-great-icons"
          "tokyo-night"
        ];
        description = ''
          Extensions to auto-install. Merged into settings as {option}`auto_install_extensions`.
        '';
      };

      extraPackages = lib.mkOption {
        type = types.listOf types.package;
        default = [
          pkgs.rust-analyzer
        ];
        description = ''
          Extra packages to make available in Zed's PATH. Useful for language servers and other tooling.
        '';
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = [ zedPackage ];

      system.xdg.menu.itemOverrides = [
        { source = "${pkgs.zed-editor}/share/applications/dev.zed.Zed.desktop"; categories = "Development"; }
      ];
    })

    (lib.mkIf (cfg.enable && mergedSettings != { }) {
      files.all."${settingsFilePath}".weakCopy = jsonFormat.generate "zed-user-settings" mergedSettings;
    })

    (lib.mkIf (cfg.enable && cfg.keymaps != [ ]) {
      files.all."${keymapFilePath}".weakCopy = jsonFormat.generate "zed-keymaps" cfg.keymaps;
    })

    (lib.mkIf (cfg.enable && cfg.userTasks != [ ]) {
      files.all."${tasksFilePath}".weakCopy = jsonFormat.generate "zed-user-tasks" cfg.userTasks;
    })
  ];
}
