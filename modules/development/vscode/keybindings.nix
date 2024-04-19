# Visual Studio Code keybindings.json
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, keybindingsFilePath, ... }: with lib.types;
let
  cfg = config.programs.vscode;

  jsonFormat = pkgs.formats.json { };
  dropNullFields = lib.filterAttrs (_: v: v != null);

in
{
  options = {
    programs.vscode.keybindings = lib.mkOption {
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
      default = [
        {
          key = "ctrl+shift+s";
          command = "workbench.action.files.saveAll";
        }
        {
          key = "ctrl+shift+t";
          command = "workbench.action.tasks.test";
        }
        {
          key = "ctrl+shift+r";
          command = "workbench.action.tasks.runTask";
          args = "Run";
        }
        {
          key = "ctrl+f12";
          command = "editor.action.goToDeclaration";
          when = "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
        }
        {
          key = "f12";
          command = "-editor.action.goToDeclaration";
          when = "editorHasDefinitionProvider && editorTextFocus && !isInEmbeddedEditor";
        }
      ];
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
  };

  config = lib.mkIf cfg.enable {
    files.all."${keybindingsFilePath}".copy = jsonFormat.generate "vscode-keybindings" (map dropNullFields cfg.keybindings);
  };
}
