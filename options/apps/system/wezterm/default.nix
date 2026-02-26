# Wezterm
# A GPU-accelerated cross-platform terminal emulator and multiplexer.
#
# ### Details
# - Configured with font, color scheme, and opacity options
# - Includes zen-mode integration for neovim
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.wezterm;
  xft = config.system.x11.xft;

  confFile = lib.mkIf cfg.enable
    (pkgs.writeText "wezterm.lua" ''
      local wezterm = require("wezterm")
      local config = wezterm.config_builder()

      -- Font
      config.font = wezterm.font("${xft.monospace}")
      config.font_size = ${cfg.fontSize}

      -- Appearance
      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
      }
      config.color_scheme = "${cfg.colorScheme}"
      config.window_background_opacity = ${cfg.opacity}
      config.hide_tab_bar_if_only_one_tab = true
      config.adjust_window_size_when_changing_font_size = false

      -- Other
      config.audible_bell = "Disabled"
      config.scrollback_lines = 10000

      -- Tab switching with Ctrl+{number}
      config.keys = {
        { key = "1", mods = "CTRL", action = wezterm.action.ActivateTab(0) },
        { key = "2", mods = "CTRL", action = wezterm.action.ActivateTab(1) },
        { key = "3", mods = "CTRL", action = wezterm.action.ActivateTab(2) },
        { key = "4", mods = "CTRL", action = wezterm.action.ActivateTab(3) },
        { key = "5", mods = "CTRL", action = wezterm.action.ActivateTab(4) },
        { key = "6", mods = "CTRL", action = wezterm.action.ActivateTab(5) },
        { key = "7", mods = "CTRL", action = wezterm.action.ActivateTab(6) },
        { key = "8", mods = "CTRL", action = wezterm.action.ActivateTab(7) },
        { key = "9", mods = "CTRL", action = wezterm.action.ActivateTab(8) },
      }

      -- Zen-mode integration for neovim
      wezterm.on("user-var-changed", function(window, pane, name, value)
        local overrides = window:get_config_overrides() or {}
        if name == "ZEN_MODE" then
          local incremental = value:find("+")
          local number_value = tonumber(value)
          if incremental ~= nil then
            while number_value > 0 do
              window:perform_action(wezterm.action.IncreaseFontSize, pane)
              number_value = number_value - 1
            end
            overrides.enable_tab_bar = false
          elseif number_value < 0 then
            window:perform_action(wezterm.action.ResetFontSize, pane)
            overrides.enable_tab_bar = true
          else
            overrides.font_size = number_value
            overrides.enable_tab_bar = false
          end
        end
        window:set_config_overrides(overrides)
      end)

      return config
    '');
in
{
  options = {
    apps.system.wezterm = {
      enable = lib.mkEnableOption "Install and configure Wezterm";

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

      colorScheme = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Color scheme name to use";
        default = "Tokyo Night Storm";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ wezterm ];

    files.all.".config/wezterm/wezterm.lua".weakCopy = confFile;
  };
}
