# Visual Studio Code keybindings.json
#---------------------------------------------------------------------------------------------------
{
  development.vscode.keybindings = [
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
}
