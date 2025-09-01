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
  cfg = config.apps.system.neovim;

in
{
  options = {
    apps.system.neovide = {
      enable = lib.mkEnableOption "Install and configure Neovide";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ neovide ];
  };
}
