# Neovim configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {

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

  files.all.".config/nvim/init.vim".copy = ../../include/home/.config/nvim/init.vim;
}
