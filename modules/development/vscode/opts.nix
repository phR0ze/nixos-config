
# Visual Studio Code user settings
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }: with lib.types;
let
  cfg = config.programs.vscode;

  jsonFormat = pkgs.formats.json { };
  dropNullFields = lib.filterAttrs (_: v: v != null);

  userDir = ".config/Code/User";
  settingsFilePath = "${userDir}/settings.json";
  keybindingsFilePath = "${userDir}/keybindings.json";
  tasksFilePath = "${userDir}/tasks.json";
  snippetDir = "${userDir}/snippets";
  extensionsFilePath = ".vscode/extensions/extensions.json";

in
{
  options = {
    programs.vscode = {
      enable = lib.mkEnableOption "Visual Studio Code";

      enableUpdateCheck = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable update checks/notifications.";
      };

      enableExtensionUpdateCheck = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable update notifications for extensions.";
      };

      workbenchIconTheme = lib.mkOption {
        type = types.str;
        default = "vscode-great-icons";
        description = "Excellent icon theme for vscode";
      };

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            "files.autoSave" = "off";
            "[nix]"."editor.tabSize" = 2;
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          {file}`settings.json`.
        '';
      };

      keybindings = lib.mkOption {
        type = types.listOf (types.submodule {
          options = {
            key = lib.mkOption {
              type = types.str;
              example = "ctrl+c";
              description = "The key or key-combination to bind.";
            };

            command = lib.mkOption {
              type = types.str;
              example = "editor.action.clipboardCopyAction";
              description = "The VS Code command to execute.";
            };

            when = lib.mkOption {
              type = types.nullOr (types.str);
              default = null;
              example = "textInputFocus";
              description = "Optional context filter.";
            };

            # https://code.visualstudio.com/docs/getstarted/keybindings#_command-arguments
            args = lib.mkOption {
              type = types.nullOr (jsonFormat.type);
              default = null;
              example = { direction = "up"; };
              description = "Optional arguments for a command.";
            };
          };
        });
        default = [ ];
        example = literalExpression ''
          [
            {
              key = "ctrl+c";
              command = "editor.action.clipboardCopyAction";
              when = "textInputFocus";
            }
          ]
        '';
        description = ''
          Keybindings written to Visual Studio Code's
          {file}`keybindings.json`.
        '';
      };

      userTasks = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            version = "2.0.0";
            tasks = [
              {
                type = "shell";
                label = "Hello task";
                command = "hello";
              }
            ];
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          {file}`tasks.json`.
        '';
      };

      extensions = lib.mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
        description = ''
          The extensions Visual Studio Code should be started with. 
        '';
      };

      languageSnippets = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = {
          haskell = {
            fixme = {
              prefix = [ "fixme" ];
              body = [ "$LINE_COMMENT FIXME: $0" ];
              description = "Insert a FIXME remark";
            };
          };
        };
        description = "Defines user snippets for different languages.";
      };

      globalSnippets = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = {
          fixme = {
            prefix = [ "fixme" ];
            body = [ "$LINE_COMMENT FIXME: $0" ];
            description = "Insert a FIXME remark";
          };
        };
        description = "Defines global user snippets.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      environment.systemPackages = with pkgs; [ vscode ];
    })

    # configure settings
    (lib.mkIf (cfg.enable && cfg.settings != { }) {
      files.all."${settingsFilePath}".copy = jsonFormat.generate "vscode-user-settings" (cfg.settings
        // lib.optionalAttrs (!cfg.enableUpdateCheck) { "update.mode" = "none"; }
        // lib.optionalAttrs (!cfg.enableExtensionUpdateCheck) { "extensions.autoCheckUpdates" = false; }
        // lib.optionalAttrs (cfg.workbenchIconTheme != "") { "workbench.iconTheme" = "${cfg.workbenchIconTheme}"; });
    })

    # configure keybindings
    (lib.mkIf (cfg.enable && cfg.keybindings != [ ]) {
      files.all."${keybindingsFilePath}".copy = jsonFormat.generate "vscode-keybindings" (map dropNullFields cfg.keybindings);
    })

#      (lib.mkIf (cfg.userTasks != { }) {
#        "${tasksFilePath}".source =
#          jsonFormat.generate "vscode-user-tasks" cfg.userTasks;
#      })

    (lib.mkIf (cfg.extensions != [ ]) (let
      files.all."${extensionsFilePath}".copy = jsonFormat.generate "vscode-extensions"
        pkgs.vscode-utils.toExtensionJson cfg.extensions;
    }))

#      (lib.mkIf (cfg.globalSnippets != { })
#        (let globalSnippets = "${snippetDir}/global.code-snippets";
#        in {
#          "${globalSnippets}".source =
#            jsonFormat.generate "user-snippet-global.code-snippets"
#            cfg.globalSnippets;
#        }))
#
#      (lib.mapAttrs' (language: snippet:
#        lib.nameValuePair "${snippetDir}/${language}.json" {
#          source = jsonFormat.generate "user-snippet-${language}.json" snippet;
#        }) cfg.languageSnippets)
  ];
}
