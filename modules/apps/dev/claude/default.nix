# Claude Code
# 
# ### Purpose
# - Exposes Claude Code configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.claude;
  host = config.host;
  homeDir = "/home/${host.user.name}";
in
{
  options = {
    apps.dev.claude = {
      enable = lib.mkEnableOption "Install and configure Claude Code";

      extraInstructions = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Machine-specific instructions appended to the base CLAUDE.md deployed to
          '${homeDir}/.claude/CLAUDE.md'. Set this per-host (e.g. in a host's
          configuration.nix) to layer on host-specific context without editing the shared base.
        '';
      };
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

      # Deploy settings.json, substituting the home directory for the target host's user
      files.user.".claude/settings.json".copy =
        builtins.replaceStrings [ "@HOME@" ] [ homeDir ] (lib.fileContents ./include/settings.json);

      # Deploy the global CLAUDE.md instructions, appending any host-specific instructions
      files.user.".claude/CLAUDE.md".copy =
        let base = lib.fileContents ./include/CLAUDE.md;
        in if (cfg.extraInstructions == "") then base
           else "${cfg.extraInstructions}\n${base}";

      # Install the docs skill as a link to the nix store
      files.user.".claude/skills/docs".link = ./include/skills/docs;

      # Install the markdown skill as a link to the nix store
      files.user.".claude/skills/markdown".link = ./include/skills/markdown;

      # Install the define skill as a link to the nix store
      files.user.".claude/skills/define".link = ./include/skills/define;
    })
  ];
}
