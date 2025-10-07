# Neovim configuration
#
# ### Key Mappings
# - n Normal mode map. Defined using :nmap or nnoremap
# - i Insert mode map. Defined using :imap or inoremap
# - v Visual and select mode map. Defined using :vmap or vnoremap
# - x Visual mode map. Defined using :xmap or xnoremap
# - s Select mode map. Defined using :smap or snoremap
# - c Command-line mode map. Defined using :cmap or cnoremap
# - noremap ignores other mappings - always use this mode
#
# ### Details
# - options nixos/modules/programs/neovim.nix
#
# ### References
# - [XVim](https://github.com/ck3mp3r/xvim/tree/main)
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.system.neovim;

in
{
  options = {
    apps.system.neovim = {
      enable = lib.mkEnableOption "Install and configure Neovim";
    };
  };

  config = lib.mkIf (cfg.enable) {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure = {

        # Load the neovim static dotfile from includes
        #customRC = builtins.readFile ../../../include/home/.config/nvim/init.vim;
        customRC = ''
          " Code settings
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""


          " Color settings
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
          "syntax on                                   " Turn on syntax hi-lighting
          "set t_Co=256                                " Enable 256 colors for terminal mode
          "set background=dark                         " Set vim color mode (dark or light)
          "colorscheme deus                            " Set the default color scheme

          " Code settings
          """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

         "nnoremap <C-f> :NERDTreeToggle<cr>          " Toggle nerd tree with Ctrl+f
        '';

        # Build an aggregate package with all plugins
        packages.aggregatePlugins = with pkgs.vimPlugins; {

          # Plugins loaded on boot
          start = [
            # Interface
            #nerdtree              # File explorer sidebar
            #vim-airline           # Awesome status bar at bottom with git support
            #vim-airline-themes    # Vim Airline themes
            #vim-devicons          # Sweet folder/file icons for nerd tree
            # Color Schemes
            #vim-deus              # Deus color scheme
            # Languages
            #vim-nix               # Syntax highlightng, .nix file detection


            # [mini.pairs](https://github.com/nvim-mini/mini.pairs)
            # Automatically inserts a matching closing character when you type an opening character like ", [, or (.
          ];

          # Plugins installed but not loaded on boot
          # Manually load by calling `:packadd $plugin-name`
          opt = [ ];
        };
      };
    };

    # Set environment variables
    environment.variables.EDITOR = "nvim";            # Set the editor to use
    environment.variables.VISUAL = "nvim";            # Set the editor to use
    environment.variables.KUBE_EDITOR = "nvim";       # Set the editor to use for Kubernetes edit commands

    # Install supporting packages
    environment.systemPackages = with pkgs; [
      vimPlugins.LazyVim
      vimPlugins.codecompanion-nvim
    ];

    # Set the correct category for neovim
    services.xdg.menu.itemOverrides = [{
      categories = "Development";
      source = "${pkgs.neovim}/share/applications/nvim.desktop";
    }];
  };
}
