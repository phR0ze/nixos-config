# Claude Code
#
# ### Purpose
# - Exposes Claude Code configuration options to the flake
#
# ### OAuth token login
# 1. On a logged in machine generate a long lived token with:
#    claude setup-token
# 2. Add it to the host's sops encrypted secrets.enc.yaml
#    ```yaml
#    claude:
#      oauthToken: <TOKEN>
#    ```
# The secret is installed readable by the `wheel` group (the admin's name is a runtime only secret)
# and exported as `CLAUDE_CODE_OAUTH_TOKEN` by a wrapper around the `claude` binary.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.dev.claude;
  claude = pkgs.callPackage ./package.nix {};
  tokenPath = config.secret.files.${cfg.oauthToken.key}.path;

  # Export the token from the runtime secret unless the caller already set one
  claudeWithToken = pkgs.symlinkJoin {
    name = "claude-code-${claude.version}";
    paths = [ claude ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude --run '
        if [ -z "''${CLAUDE_CODE_OAUTH_TOKEN:-}" ] && [ -r ${tokenPath} ]; then
          export CLAUDE_CODE_OAUTH_TOKEN="$(cat ${tokenPath})"
        fi'
    '';
  };
in
{
  options = {
    apps.dev.claude = {
      enable = lib.mkEnableOption "Install and configure Claude Code";

      sopsFile = lib.mkOption {
        description = ''
          Path to this host's sops-encrypted secrets file holding the OAuth token. Nullable so
          modules/default.nix can forward `host.sopsFile` here unconditionally - required via an
          assertion when `oauthToken.enable` is set.
        '';
        type = nullOr path;
        default = null;
      };

      oauthToken = {
        enable = lib.mkOption {
          description = "Authenticate with a `claude setup-token` OAuth token from sops";
          type = bool;
          default = true;
        };
        key = lib.mkOption {
          description = "Key path within `sopsFile` holding the OAuth token";
          type = str;
          default = "claude/oauthToken";
        };
      };
    };
  };

  config = lib.mkIf (cfg.enable) (lib.mkMerge [
    {
      environment.systemPackages = [
        (if cfg.oauthToken.enable then claudeWithToken else claude)
      ];

      # Seed Claude's global state to skip the first-run onboarding (theme picker etc).
      # weakCopy only writes when missing: Claude mutates this file constantly at runtime.
      files.user.".claude.json".weakCopy = builtins.toJSON {
        hasCompletedOnboarding = true;
        lastOnboardingVersion = claude.version;
        theme = "dark";
      };

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
    }

    (lib.mkIf (cfg.oauthToken.enable) {
      assertions = [
        {
          assertion = cfg.sopsFile != null;
          message = "apps.dev.claude.sopsFile must be set when apps.dev.claude.oauthToken.enable is enabled";
        }
      ];

      secret.files.${cfg.oauthToken.key} = {
        sopsFile = cfg.sopsFile;
        group = "wheel";
        filemode = "0440";
      };
    })
  ]);
}
