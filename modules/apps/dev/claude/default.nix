# Claude Code
# 
# ### Purpose
# - Exposes Claude Code configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.claude;
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

      files.user.".claude/CLAUDE.md".copy = ./include/CLAUDE.md;
      files.user.".claude/settings.json".copy = ./include/settings.json;
      files.user.".claude/skills/docs".link = ./include/skills/docs;
      files.user.".claude/skills/markdown".link = ./include/skills/markdown;
      files.user.".claude/skills/define".link = ./include/skills/define;
    })
  ];
}
