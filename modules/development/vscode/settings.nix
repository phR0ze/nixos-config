# Visual Studio Code user settings
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, settingsFilePath, ... }: with lib.types;
let
  xft = config.services.xserver.xft;

in
{
  programs.vscode.settings = {
    # Explorer configuration
    # ----------------------------------------------------------------------------------------
    "explorer.confirmDelete" = false;               # Ask for confirmation when deleting a file
    "explorer.confirmDragAndDrop" = false;          # Ask for confirmation when moving file and folders
    "telemetry.telemetryLevel" = "off";             # Don't phone home with details of usage

    # Integrated terminal configuration
    # ----------------------------------------------------------------------------------------
    "terminal.explorerKind" = "integrated";         # What kind of terminal to use inside vscode
    "terminal.integrated.fontFamily" = "${xft.monospace}";
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
    "editor.fontFamily" = "${xft.monospace}";

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
}
