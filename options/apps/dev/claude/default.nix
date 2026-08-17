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

      extraInstructions = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Machine-specific instructions appended to the base CLAUDE.md deployed to
          '${homeDir}/.claude/CLAUDE.md'. Set this per-machine (e.g. in a machine's
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

      # Deploy settings.json, substituting the home directory for the target machine's user
      files.user.".claude/settings.json".text =
        builtins.replaceStrings [ "@HOME@" ] [ homeDir ] (lib.fileContents ./include/settings.json);

      # Deploy the global CLAUDE.md instructions, appending any machine-specific instructions
      files.user.".claude/CLAUDE.md".text =
        let base = lib.fileContents ./include/CLAUDE.md;
        in if (cfg.extraInstructions == "") then base
           else "${cfg.extraInstructions}\n${base}";

      # Install the docs skill as a link to the nix store
      files.user.".claude/skills/docs".link = ./include/skills/docs;

      # Install the markdown skill as a link to the nix store
      files.user.".claude/skills/markdown".link = ./include/skills/markdown;
    })
  ];
}
