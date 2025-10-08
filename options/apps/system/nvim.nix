# Nvim configuration
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
# ### References
# - [XVim](https://github.com/ck3mp3r/xvim/tree/main)
# - [Lazyvim Nix](https://github.com/jla2000/lazyvim-nix)
# - [Nvim-bundle](https://github.com/jla2000/nvim-bundle)
# - [nixCats](https://github.com/BirdeeHub/nixCats-nvim)
# - [lz.n](https://github.com/lumen-oss/lz.n)
#
# ### Details
# - All plugins are built from nixpkgs
# - Configuration is all written in lua
# - Plugins are lazy loaded using lz.n
# - Lua config can be changed at runtime
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  cfg = config.apps.system.nvim;
  x11 = config.system.x11;
  user = config.machine.user.name;

  pluginPath = import ./nvim/plugins.nix { inherit lib pkgs; };
in
{
  options = {
    apps.system.nvim = {
      enable = lib.mkEnableOption "Install and configure Nvim";
    };
  };

  config = lib.mkMerge [

    # Include the essential dependencies for nvim in X11
    (lib.mkIf (x11.enable && cfg.enable) {

      # Set the correct category for nvim
      system.xdg.menu.itemOverrides = [{
        categories = "Development";
        source = "${pkgs.neovim}/share/applications/nvim.desktop";
      }];
    })

    # Nvim configuration
    (lib.mkIf (cfg.enable) {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        configure = {

          # Load the init.lua configuration file
          #customLuaRC = ''
          #  vim.opt.rtp:prepend("${./nvim}")
          #  dofile("${./nvim/init.lua}")
          #'';
          customRC = ''
            let g:plugin_path = "${pluginPath}"
          '';

          # Now load the plugin manager which will load all other plugins
          packages.all.start = [ pkgs.vimPlugins.lazy-nvim ];

          #packages.aggregatePlugins = with pkgs.vimPlugins; {
            # Plugins loaded on boot
          #  start = [
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
          #  ];

            # Plugins installed but not loaded on boot
            # Manually load by calling `:packadd $plugin-name`
          #  opt = [ ];
        };
      };

      # Set environment variables
      environment.variables.EDITOR = "nvim";            # Set the editor to use
      environment.variables.VISUAL = "nvim";            # Set the editor to use
      environment.variables.KUBE_EDITOR = "nvim";       # Set the editor to use for Kubernetes edit commands

      # Install supporting packages
      environment.systemPackages = with pkgs; [
        #vimPlugins.LazyVim
        #vimPlugins.codecompanion-nvim
      ];
    })
  ];
}
