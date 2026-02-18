# Neovim
# 
# ### Purpose
# - Exposes Neovim configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.system.neovim;
  x11 = config.system.x11;
in
{
  options = {
    apps.system.neovim = {
      enable = lib.mkEnableOption "Install and configure Neovim";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (x11.enable && cfg.enable) {

      # Set the correct category for nvim
      system.xdg.menu.itemOverrides = [{
        categories = "Development";
        source = "${pkgs.neovim}/share/applications/nvim.desktop";
      }];
    })

    # Nvim configuration
    (lib.mkIf (cfg.enable) {

      # Set environment variables
      environment.variables.EDITOR = "nvim";            # Set the editor to use
      environment.variables.VISUAL = "nvim";            # Set the editor to use
      environment.variables.KUBE_EDITOR = "nvim";       # Set the editor to use for Kubernetes edit commands

      # Install supporting packages
      environment.systemPackages = [
        (pkgs.callPackage ./package.nix {})             # Call the local neovim package
      ];

      # Create default style configurations
      files.user.".config/stylua/stylua.toml".link = (
        pkgs.writeText "stylua.toml" ''
          indent_type = "Spaces"
          indent_width = 2
        ''
      );
    })
  ];
}
