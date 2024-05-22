# Neovim configuration
#
# ### Details
# - options nixos/modules/programs/neovim.nix
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.programs.neovim;

in
{
  config = lib.mkIf (cfg.enable) {
    programs.neovim = {
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure = {

        # Load the neovim static dotfile from includes
        customRC = builtins.readFile ../../include/home/.config/nvim/init.vim;

        # Build an aggregate package with all plugins
        packages.aggregatePlugins = with pkgs.vimPlugins; {

          # Plugins loaded on boot
          start = [

            # Interface
            nerdtree              # File explorer sidebar
            vim-airline           # Awesome status bar at bottom with git support
            vim-airline-themes    # Vim Airline themes
            vim-devicons          # Sweet folder/file icons for nerd tree

            # Color Schemes
            vim-deus              # Deus color scheme
          ];

          # Plugins installed but not loaded on boot
          # Manually load by calling `:packadd $plugin-name`
          opt = [ ];
        };
      };
    };

    # Set the correct category for neovim
    services.xdg.menu.itemOverrides = [
      {
        categories = "Development";
        source = "${pkgs.neovim}/share/applications/nvim.desktop";
      }
    ];
  };
}
