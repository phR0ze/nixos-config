# Neovim configuration
#
# ### References
# - [Lazyvim Nix](https://github.com/jla2000/lazyvim-nix)
# - [Nvim-bundle](https://github.com/jla2000/nvim-bundle)
# - [Neovim Wrapper](https://ayats.org/blog/neovim-wrapper)
# - [NixVim](https://github.com/nix-community/nixvim)
# - [Frosty Vim](https://github.com/SystematicError/frosty-vim)
# - [Lz.n](https://github.com/lumen-oss/lz.n)
#
# ### Details
# - Configuration is all written in lua
# - Plugins are lazy loaded using lz.n
#---------------------------------------------------------------------------------------------------
{
  neovim-unwrapped, symlinkJoin, fetchFromGitHub, makeWrapper, runCommandLocal, vimPlugins, vimUtils,
  writeTextFile, lib, pkgs
}: let

  # Plugins to make available but don't load on boot.
  # - these will be lazy loaded by lz-n as needed based on triggers
  # - end up in ./result/pack/plugins/opt
  plugins = with vimPlugins; [
    lz-n                            # Light weight lazy plugin loader

    # Colorschemes
    gruvbox-nvim                    # Lua port of the most famous vim colorscheme
    tokyonight-nvim                 # A clean dark Neovim theme
    catppuccin-nvim                 # Soothing pastel theme for NeoVIM

    # ----------------------------------------------------------------------------------------------
    # Essential plugins
    # - ./config/lua/plugins/0000-essential.lua
    # ----------------------------------------------------------------------------------------------

    # Modern, minimal, pure lua replacement for nvim-web-devicons
    # - configuration ./config/lua/plugins/0000-mini-icons.lua
    # - can patch itself into plugins expecting nvim-web-devicons thus eliminating the need for both
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "mini.icons"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-mini"; repo = "mini.icons";
        rev = "v0.16.0"; sha256 = "sha256-/sdLtMOOGeVvFDBB9N4CyUHpGXtUi1ZJ9dIpvxZ9C4Q="; };
      doCheck = false; doNvimRequireCheck = false; })

    # Intelligent pairing, better than mini.pairs
    # - configuration ./config/lua/plugins/0000-nvim-autopairs.lua
    # - does so intelligently with context awareness unlike the LazyVim's choice of mini.pairs
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "nvim-autopairs"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "windwp"; repo = "nvim-autopairs";
        rev = "7a2c97cccd60abc559344042fefb1d5a85b3e33b";
        sha256 = "sha256-cRIg1qO3WMxzcDQti0GEJl77KnlRCqyBN+g76PviWt0="; };
      doCheck = false; doNvimRequireCheck = false; })

    # Persistence is a simple lua plugin for automated session management.
    # - configuration ./config/lua/plugins/0000-persistence-nvim.lua
    # - saves active session under ~/.local/state/nvim/sessions on exit
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "persistence.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "persistence.nvim";
        rev = "v3.1.0"; sha256 = "sha256-xZij+CYjAoxWcN/Z2JvJWoNkgBkz83pSjUGOfc9x8M0="; };})

    # Better comments and override support for treesitter languages
    # - configuration ./config/lua/plugins/0000-ts-comments-nvim.lua
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "ts-comments.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "ts-comments.nvim";
        rev = "v1.5.0";
        sha256 = "sha256-nYdU5KlSSgxWgxu/EgpBUNDQ9zEXkEbiTkBO4ThHPfo="; };})

    # A snazy pure lua buffer line
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "bufferline.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "akinsho"; repo = "bufferline.nvim";
        rev = "v4.9.1"; sha256 = "sha256-ae4MB6+6v3awvfSUWlau9ASJ147ZpwuX1fvJdfMwo1Q="; };
      doCheck = false; doNvimRequireCheck = false; })

    # - configuration ./config/lua/plugins/0100-lualine-nvim.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "lualine.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-lualine"; repo = "lualine.nvim";
        rev = "3946f0122255bc377d14a59b27b609fb3ab25768";
        sha256 = "sha256-hdrAdG3hC2sAevQ6a9xizqPgEgnNKxuc5rBYn0pKM1c="; };})

    # Collection of plugins you enable in the configuration
    # Blazing fast neovim statusline written in pure lua
    # Include nvim-treesitter (TS) parsers along with the plugin
    # - modern parser for faster, more accurate syntax highlighting and language awareness
    # - parsers get included at `nvim-treesitter/parser/` which is autoloaded by TS
    # - all grammars can be included with nvim-treesitter.withAllGrammars.dependencies
    # - no external dependencies
    (symlinkJoin {
      name = "nvim-treesitter"; # use the same name to match plugin name expectations
      paths = [ nvim-treesitter (nvim-treesitter.withPlugins (x: [
        x.bash
        x.diff
        x.dart
        x.go
        x.html
        x.javascript
        x.jsdoc
        x.json
        x.lua
        x.luadoc
        x.nix           # provides inline syntax hilighting support
        x.markdown
        x.markdown_inline
        x.printf
        x.python
        x.regex
        x.ruby
        x.rust
        x.toml
        x.vim
        x.vimdoc
        x.xml
        x.yaml
      ])).dependencies];
    })

    # Builds on treesitter to provide context about your code objects
    # - depends on treesitter
    (vimUtils.buildVimPlugin {
      pname = "nvim-treesitter-context"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-treesitter"; repo = "nvim-treesitter-context";
        rev = "ec308c7827b5f8cb2dd0ad303a059c945dd21969";
        sha256 = "sha256-QdZstxKsEILwe7eUZCmMdyLPyvNKc/e7cfdYQowHWPQ="; };})

    # Builds on treesitter to provide code navigation motions 
    # - depends on treesitter
    (vimUtils.buildVimPlugin {
      pname = "nvim-treesitter-textobjects"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-treesitter"; repo = "nvim-treesitter-textobjects";
        rev = "5ca4aaa6efdcc59be46b95a3e876300cfead05ef";
        sha256 = "sha256-lf+AwSu96iKO1vWWU2D7jWHGfjXkbX9R2CX3gMZaD4M="; };
      doCheck = false; doNvimRequireCheck = false; })

    # - configuration ./config/lua/plugins/0100-snacks-nvim.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "snacks.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "snacks.nvim";
        rev = "v2.27.0"; sha256 = "sha256-QkcOKPgiJeA5LmQvC7DZ6ddjaoW8AE5I08Gm8jlEkT8="; };
      doCheck = false; doNvimRequireCheck = false; })

    # Pops up a window on different hot keys that shows keymaps as you are typing
    # - configuration ./config/lua/plugins/0100-which-key.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "which-key.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "which-key.nvim";
        rev = "v3.17.0"; sha256 = "sha256-kYpiw2Syu54B/nNVqTZeUHJIPNzAv3JpFaMWR9Ai3p4="; };
      doCheck = false; doNvimRequireCheck = false; })

    # Navigate code with search labels, enhanced character motions and Treesitter integration
    # - configuration ./config/lua/plugins/0100-flash-nvim.lua
    # - depends on treesitter
    (vimUtils.buildVimPlugin {
      pname = "flash.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "flash.nvim";
        rev = "v2.1.0"; sha256 = "sha256-Qh9ty28xtRS3qXxE/ugx9FqAKrdeFGEf7W6yEORnZV8="; };
        doCheck = false; doNvimRequireCheck = false; })

    # ----------------------------------------------------------------------------------------------
    # Writer related plugins
    # - ./config/lua/plugins/0200-writer.lua
    # ----------------------------------------------------------------------------------------------

    # Twilight dims inactive portions of the code you're editing.
    (vimUtils.buildVimPlugin {
      pname = "twilight.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "twilight.nvim";
        rev = "664e752f4a219801265cc3fc18782b457b58c1e1";
        sha256 = "sha256-V6DFwvShvX6mYMRJajwOaxbHMNuCHCZzVrfT73iMuQo="; };})

    # Zen mode for distraction free writing
    (vimUtils.buildVimPlugin {
      pname = "zen-mode.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "zen-mode.nvim";
        rev = "v1.4.1"; sha256 = "sha256-vRJynz3bnkhfHKya+iEgm4PIEwT2P9kvkskgTt5UUU4="; };})

    # ----------------------------------------------------------------------------------------------
    # LSP related plugins
    # - ./config/lua/plugins/0300-lsp.lua
    # ----------------------------------------------------------------------------------------------

    # Manage crates.io dependencies with autocompletion of versions and features
    (vimUtils.buildVimPlugin {
      pname = "crates.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "saecki"; repo = "crates.nvim";
        rev = "v0.7.1"; sha256 = "sha256-9BE6Co+519h5RswwmEnW6Od5hPcet47BwoXNMZaYAx8="; };
        doCheck = false; doNvimRequireCheck = false; })

    # Fidget shows LSP logging output in the bottom right hand side
    (vimUtils.buildVimPlugin {
      pname = "fidget.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "j-hui"; repo = "fidget.nvim";
        rev = "v1.6.1"; sha256 = "sha256-W0l2XW8/MfMRkQYr4AvXT4md2OPe8CD4hAHTtsJpU5w="; };})

    # nvim-lspconfig assists in LSP configuration
    # - depends on treesitter, snacks.picker, mini.icons
    (vimUtils.buildVimPlugin {
      pname = "nvim-lspconfig"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "neovim"; repo = "nvim-lspconfig";
        rev = "v2.5.0"; sha256 = "sha256-BrY4l2irKsAmxDNPhW9eosOwsVdZjULyY6AOkqTAU4E="; };})

    # Lazydev provides a ready made Lua LSP configuration which fixes some errors
    # - depends on nvim-lspconfig
    (vimUtils.buildVimPlugin {
      pname = "lazydev.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "lazydev.nvim";
        rev = "v1.10.0"; sha256 = "sha256-sqtdijEnUZrgp+4GKpetZmenA4hkFNHk/jw57y+25co="; };})

    # Rustaceanvim provides a ready made Rust LSP configuration to handle all the things
    # - depends on nvim-dap, lldb, rust-analyzer
    (vimUtils.buildVimPlugin {
      pname = "rustaceanvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "mrcjkb"; repo = "rustaceanvim";
        rev = "v7.0.6"; sha256 = "sha256-t7xAQ9sczLyA1zODmD+nEuWuLnhrfSOoPu/4G/YTGdU="; };
        doCheck = false; doNvimRequireCheck = false; })

    # Conform provides code formatting for various languages
    # - depends ?
    (vimUtils.buildVimPlugin {
      pname = "conform.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "stevearc"; repo = "conform.nvim";
        rev = "v9.1.0"; sha256 = "sha256-pUF9F5QoDzCZuVRcJEF91M8Qjkh/xosMkf9tRavkmJs="; };})

    # blink.cmp provides autocompletion
    # (vimUtils.buildVimPlugin {
    #   pname = "fidget.nvim"; version = "2025-10-30";
    #   src = fetchFromGitHub { owner = "j-hui"; repo = "fidget.nvim";
    #     rev = "v1.6.1"; sha256 = ""; };})

    #codecompanion-nvim
    #plenary-nvim
    #vim-startuptime
  ];

  # Name to give to this custom version of Neovim
  appName = "nvim-custom";

  # Build the plugins into a package for Neovim
  # - Packages are a named collection of plugins organized by mode i.e. MODE=('start' | 'opt')
  # - Packages are in the `packpath` under `pack/$NAME/$MODE/{$PLUGIN_1...$PLUGIN_n}`
  # - Plugins under the `start` sub folder are automatically loaded by nvim on boot
  # - Plugins under `opt` are available to be loaded manually with `:packadd` from within nvim
  # - All .lua files in any pack/$NAME/start/$PLUGIN/plugin/ path will be automatically loaded
  # - Lua modules are looked for in any `lua` sub-folders in any path in the `runtimepath`
  # - Lua require calls reference the folder structure e.g. `require('a.b')` for `lua/a/b.lua`
  pluginPkg = runCommandLocal "nvim-plugins" {} ''
    mkdir -p $out/pack/${appName}/{start,opt}
    ln -vsfT ${./config/lua} $out/lua
    ln -vsfT ${./config/init} $out/pack/${appName}/start/init
    ${
      lib.concatMapStringsSep "\n"
      (plugin: "ln -vsfT ${plugin} $out/pack/${appName}/opt/${lib.getName plugin}")
      plugins
    }
  '';

  # Create a simple lua init script
  # Not using this in favor of my custom plugin ./config/init which loads ./config/lua/init.lua to
  # configure Nvim with all options, keymaps, plugins etc... instead of inline like it is here. The 
  # benefits are you get Lua syntax highlighting and full Lua module support which is lacking here.
  initLua = writeTextFile {
    name = "init.lua";
    text = ''
      vim.loader.enable(true)               -- Enable Lua bytecode cache at ~/.local/share/nvim/loader
    '';
  };

  # Runtime dependencies to support Neovim and Neovim plugins
  # - this would include LSPs, utilities, linting tools etc...
  runtimeDeps = with pkgs; [
    fd                                      # Simple fast Rust alternative to find
    ripgrep                                 # Faster more capable Rust grep
    gopls                                   # GO LSP
    helm-ls                                 # Helm LSP
    stylua                                  # Lua opinionated code formatter
    lua-language-server                     # Lua LSP
    bash-language-server                    # Bash LSP
    shellcheck                              # Bash script analysis linting tool
    marksman                                # Markdown LSP
    #md-lsp                                 # Markdown LSP alternative
    nixd                                    # Nix LSP
    #crates-lsp                              # Rust cargo.toml LSP
    lldb                                    # Rust debug adaptor
    rust-analyzer                           # Rust LSP
    superhtml                               # HTML LSP
    systemd-language-server                 # Systemd LSP
    tailwindcss-language-server             # Tailwind LSP
    yaml-language-server                    # YAML LSP
    #zuban                                   # Python LSP
  ];

in 
  # symlinkJoin creates a new derivation that replaces all files in the given path with links where 
  # the files were moved to the store individually. This makes it easier to modify the original 
  # package while reusing its binaries to be efficient.
  symlinkJoin {
    name = appName;                         # Package name being created
    paths = [                               # Paths being symlinked
      neovim-unwrapped                      # Neovim and its files
      pluginPkg                             # Plugin files
    ] ++ runtimeDeps;                       # Include other runtime dependencies
    nativeBuildInputs = [makeWrapper];      # Build tools to make available during build

    # Wrap the target passing in custom arguments
    # - Nvim uses the term `pack` to refer to a collection of plugins
    # - NVIM_APPNAME defines a vim config namespace to isolate your configs from the host
    #   - essentially changes config lookup paths to `~/.config/${NVIM_APPNAME}`
    #   - this can be really useful if you want to test locally without picking up host settings
    # - Also create the alias links
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --prefix PATH : ${ lib.makeBinPath runtimeDeps } \
        --add-flags '-u' \
        --add-flags '${initLua}' \
        --add-flags '--cmd' \
        --add-flags "'set packpath^=${pluginPkg} | set runtimepath^=${pluginPkg}'" \
        --set-default NVIM_APPNAME ${appName}
      ln -s $out/bin/nvim $out/bin/vim
    '';

    # Make the plugins derivation available for build commands like
    # nix build -f ./direct.nix plugins
    passthru = {
      inherit pluginPkg;
    };
  }
