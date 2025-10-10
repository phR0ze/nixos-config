{ lib, pkgs, ... }:
let

  # Function to convert derivations into { name; path; } objects for linkFarm
  mkEntryFromDrv = x:
    if lib.isDerivation drv then { name = "${lib.getName x}"; path = x; } else x;

  plugins = with pkgs.vimPlugins; [
    LazyVim
    better-escape-nvim
    clangd_extensions-nvim
    cmp-buffer
    cmp-nvim-lsp
    cmp-path
    cmp_luasnip
    conform-nvim
    crates-nvim
    dracula-nvim
    dressing-nvim
    flash-nvim
    friendly-snippets
    gitsigns-nvim
    headlines-nvim
    indent-blankline-nvim
    kanagawa-nvim
    lualine-nvim
    marks-nvim
    neo-tree-nvim
    neoconf-nvim
    neodev-nvim
    neorg
    nix-develop-nvim
    noice-nvim
    none-ls-nvim
    nui-nvim
    nvim-cmp
    nvim-dap
    nvim-dap-ui
    nvim-dap-virtual-text
    nvim-lint
    nvim-lspconfig
    nvim-notify
    nvim-spectre
    nvim-treesitter
    nvim-treesitter-context
    nvim-treesitter-textobjects
    nvim-ts-autotag
    nvim-ts-context-commentstring
    nvim-web-devicons
    oil-nvim
    overseer-nvim
    persistence-nvim
    plenary-nvim
    project-nvim
    rust-tools-nvim
    sqlite-lua
    telescope-fzf-native-nvim
    telescope-nvim
    tmux-navigator
    todo-comments-nvim
    tokyonight-nvim
    trouble-nvim
    vim-illuminate
    vscode-nvim

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

    #codecompanion-nvim
    which-key-nvim                                # Shows available keybindings in a popup as you type
    vim-startuptime                               # 
    { name = "mini.pairs"; path = mini-pairs; }
  ];
in

# Link together all plugins into a single derivation of links to plugins e.g.
# result/
# ├── plugin1 -> /nix/store/...-plugin1-.../lua/mini/pairs.lua
# └── plugin2 -> /nix/store/...-plugin2-.../lua/marks/init.lua
pkgs.linkFarm "lazyvim-nix-plugins" (builtins.map mkEntryFromDrv plugins)
