# Visual Studio Code user settings
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }: with lib.types;
let
  cfg = config.programs.vscode;
  xftCfg = config.services.xserver.xft;

  jsonFormat = pkgs.formats.json { };

#  tasksFilePath = "${userDir}/tasks.json";
#
#  snippetDir = "${userDir}/snippets";

  extensionPath = ".${extensionDir}/extensions"; # i.e. ~/.vscode/extensions
#
#  extensionJson = pkgs.vscode-utils.toExtensionJson cfg.extensions;
#  extensionJsonFile = pkgs.writeTextFile {
#    name = "extensions-json";
#    destination = "/share/vscode/extensions/extensions.json";
#    text = extensionJson;
#  };
#

in
{
  options = {
    programs.vscode = {
      enable = lib.mkEnableOption "Visual Studio Code";

      package = lib.mkOption {
        type = types.package;
        default = pkgs.vscode;
        defaultText = literalExpression "pkgs.vscode";
        example = literalExpression "pkgs.vscodium";
        description = "Version of Visual Studio Code to install.";
      };

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

      userSettings = lib.mkOption {
        type = jsonFormat.type;
        default = {
          # Explorer configuration
          # ----------------------------------------------------------------------------------------
          "explorer.confirmDelete" = false;               # Ask for confirmation when deleting a file
          "explorer.confirmDragAndDrop" = false;          # Ask for confirmation when moving file and folders
          "telemetry.telemetryLevel" = "off";             # Don't phone home with details of usage

          # Integrated terminal configuration
          # ----------------------------------------------------------------------------------------
          "terminal.explorerKind" = "integrated";         # What kind of terminal to use inside vscode
          "terminal.integrated.fontFamily" = "${xftCfg.monospace}";
          "terminal.integrated.fontSize" = 16;
          "terminal.integrated.tabs.enabled" = false;
          "terminal.integrated.enablePersistentSessions" = false;

          # Debug configuration
          # ----------------------------------------------------------------------------------------
          "debug.console.closeOnEnd" = true;
          "debug.terminal.clearBeforeReusing" = true;

          # Editor configuration
          # ----------------------------------------------------------------------------------------
          "editor.tabSize" = 4;                           # Number of spaces per indentation-level
          "editor.insertSpaces" = true;                   # Insert spaces when pressing Tab instead of a Tab character
          "editor.detectIndentation" = false;             # Disable editor auto detection and just use spaces
          "editor.formatOnPaste" = true;                  #
          "editor.formatOnSave" = true;                   #
          "editor.minimap.enabled" = true;                #
          "editor.fontSize" = 14;
          "editor.fontFamily" = "${xftCfg.monospace}";

          # Copilot lang configuration
          # ----------------------------------------------------------------------------------------
          "github.copilot.enable" = {
            "*" = true;
            "plaintext" = true;
            "markdown" = true;
            "scminput" = false;
          };
          "git.openRepositoryInParentFolders" = "never";

          # Vim configuration
          # ----------------------------------------------------------------------------------------
          "vim.textwidth" = 100;
          "vim.handleKeys" = {
            "<C-a>" = false;
            "<C-b>" = false;
            "<C-c>" = false;
            "<C-e>" = false;
            "<C-f>" = false;
            "<C-h>" = false;
            "<C-i>" = false;
            "<C-j>" = false;
            "<C-k>" = false;
            "<C-n>" = false;
            "<C-p>" = false;
            "<C-s>" = false;
            "<C-t>" = false;
            "<C-u>" = false;
            "<C-v>" = false;
            "<C-o>" = false;
            "<C-w>" = false;
            "<C-x>" = false;
            "<C-y>" = false;
            "<C-z>" = false;
          };

          # Go lang configuration
          # ----------------------------------------------------------------------------------------
          "go.gopath" = "~/Projects/go";                  # Set the GOPATH to use
          "go.formatTool" = "goimports";                  # Use specific external format tool for go
          "go.useLanguageServer" = true;                  # Use the new gopls language server
          "[go]" = {
            "editor.snippetSuggestions" = "none";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = true;
            };
          };
          "gopls" = {
              "usePlaceholders" = false;                  # add parameter placeholders when completing a function
              "completionDocumentation" = true;           # for documentation in completion items
          };
          "go.toolsManagement.autoUpdate" = true;         # autoupdate gopls tools
          "files.eol" = "\n";                             # gopls formatting only supports LF line endings

          # Rust lang configuration
          # ----------------------------------------------------------------------------------------
          "rust-analyzer.inlayHints.parameterHints.enable" = false;
          "rust-analyzer.inlayHints.typeHints.enable" = false;
          "rust-analyzer.hover.actions.debug.enable" = false;
          "rust-analyzer.hover.actions.run.enable" = false;
          "rust-analyzer.inlayHints.closingBraceHints.enable" = false;
          "rust-analyzer.inlayHints.chainingHints.enable" = false;

          # Dart lang configuration
          # ----------------------------------------------------------------------------------------
          "dart.lineLength" = 100;
          "dart.closingLabels" = true;
        };
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

      mutableExtensionsDir = lib.mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether extensions can be installed or updated manually
          or by Visual Studio Code.
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

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cfg.package
    ];

    # configure user settings
    files.all."${configFilePath}".copy = jsonFormat.generate "vscode-user-settings" (cfg.userSettings
      // lib.optionalAttrs (!cfg.enableUpdateCheck) { "update.mode" = "none"; }
      // lib.optionalAttrs (!cfg.enableExtensionUpdateCheck) { "extensions.autoCheckUpdates" = false; }
      // lib.optionalAttrs (cfg.workbenchIconTheme != "") { "workbench.iconTheme" = "${cfg.workbenchIconTheme}"; });

#      (lib.mkIf (cfg.userTasks != { }) {
#        "${tasksFilePath}".source =
#          jsonFormat.generate "vscode-user-tasks" cfg.userTasks;
#      })

#    (lib.mkIf (cfg.extensions != [ ]) (let
#      subDir = "share/vscode/extensions";
#
#      # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
#      toPaths = ext:
#        map (k: { "${extensionPath}/${k}".source = "${ext}/${subDir}/${k}"; })
#        (if ext ? vscodeExtUniqueId then
#          [ ext.vscodeExtUniqueId ]
#        else
#          builtins.attrNames (builtins.readDir (ext + "/${subDir}")));
#    in if cfg.mutableExtensionsDir then
#      lib.mkMerge (concatMap toPaths cfg.extensions
#        ++ lib.optional (lib.versionAtLeast vscodeVersion "1.74.0") {
#          # Whenever our immutable extensions.json changes, force VSCode to regenerate
#          # extensions.json with both mutable and immutable extensions.
#          "${extensionPath}/.extensions-immutable.json" = {
#            text = extensionJson;
#            onChange = ''
#              run rm $VERBOSE_ARG -f ${extensionPath}/{extensions.json,.init-default-profile-extensions}
#              verboseEcho "Regenerating VSCode extensions.json"
#              run ${getExe cfg.package} --list-extensions > /dev/null
#            '';
#          };
#        })
#    else {
#      "${extensionPath}".source = let
#        combinedExtensionsDrv = pkgs.buildEnv {
#          name = "vscode-extensions";
#          paths = cfg.extensions
#            ++ lib.optional (lib.versionAtLeast vscodeVersion "1.74.0")
#            extensionJsonFile;
#        };
#      in "${combinedExtensionsDrv}/${subDir}";
#    }))

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
  };
}
