# Neovide
# Neovide is a simple no-nonsense, cross-platform graphical user interface for Neovim. Written in 
# Rust is appears to bridge the gap from the terminal allowing for easy window interaction from file 
# explorers and other desktop tools.
#
# ### Details
# - 
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.system.neovide;
  xft = config.system.x11.xft;

  confFile = lib.mkIf cfg.enable
    (pkgs.writeText "config.toml" ''
      [font]
      normal = ["${xft.monospace}"]
      size = ${cfg.fontSize}
    '');
in
{
  options = {
    apps.system.neovide = {
      enable = lib.mkEnableOption "Install and configure Neovide";

      fontSize = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Font size to use for displaying text in the editor";
        default = "13.5";
      };

      linespace = lib.mkOption {
        type = types.str;
        description = lib.mdDoc "Vertical space between lines/rows of text in the editor";
        default = "3";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ neovide ];

    files.all.".config/neovide/config.toml".weakCopy = confFile;
  };
}
