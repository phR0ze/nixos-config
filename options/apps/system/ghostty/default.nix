# Ghostty
# A fast, feature-rich, and cross-platform terminal emulator that uses platform-native UI.
#
# ### Review
# - window decorations don't follow system theme, seems focused on MacOS for look and feel.
# - multi-tab support was awkward and has odd terminal view for all tabs
# - tokyonight theme isn't as nice as WezTerm's
#
# ### Details
# - Configured with font, color scheme, and opacity options
# - Uses GTK on Linux
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.ghostty;
  xft = config.system.x11.xft;

  confFile = lib.mkIf cfg.enable
    (pkgs.writeText "ghostty-config" ''
      # Font
      font-family = ${xft.monospace}
      font-size = ${cfg.fontSize}

      # Appearance
      theme = ${cfg.theme}
      background-opacity = ${cfg.opacity}
      window-padding-x = 0
      window-padding-y = 0

      # Other
      scrollback-limit = 10000

      # Quake style drop-down terminal
      keybind = global:f12=toggle_quick_terminal
      quick-terminal-position = top
      quick-terminal-screen = main
      quick-terminal-autohide = unfocused
      quick-terminal-size = 50%,80%
    '');
in
{
  options = {
    apps.system.ghostty = {
      enable = lib.mkEnableOption "Install and configure Ghostty";

      fontSize = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Font size to use for displaying text in the terminal";
        default = "13";
      };

      opacity = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Window background opacity (0.0 to 1.0)";
        default = "1.0";
      };

      theme = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Theme name to use";
        default = "tokyonight_storm";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ ghostty ];

    files.all.".config/ghostty/config".weakCopy = confFile;
  };
}
