# Claude Code
# 
# ### Purpose
# - Exposes Claude Code configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.claude;
  machine = config.machine;
  homeDir = "/home/${machine.user.name}";
in
{
  options = {
    apps.dev.claude = {
      enable = lib.mkEnableOption "Install and configure Claude Code";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {

      # Install supporting packages
      environment.systemPackages = [
        (pkgs.callPackage ./package.nix {})             # Call the local package
      ];

      # Deploy the statusline script as an executable link to the nix store
      files.user.".claude/statusline.sh" = {
        link = ./include/statusline.sh;
        filemode = "0755";
      };

      # Deploy settings.json, substituting the home directory for the target machine's user
      files.user.".claude/settings.json".text =
        builtins.replaceStrings [ "@HOME@" ] [ homeDir ] (lib.fileContents ./include/settings.json);
    })
  ];
}
