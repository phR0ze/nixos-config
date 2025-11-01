# Neovim configuration for writing
#
# ### Details
# - see default.nix for more details on how this was built
#---------------------------------------------------------------------------------------------------
{
  neovim-unwrapped, symlinkJoin, fetchFromGitHub, makeWrapper, runCommandLocal, vimPlugins, vimUtils,
  writeTextFile, lib,
}: let

  plugins = with vimPlugins; [
    lz-n                            # Light weight lazy plugin loader

    # Colorschemes
    vim-deus                        # Color scheme I've used for years
    gruvbox-nvim                    # Lua port of the most famous vim colorscheme
    tokyonight-nvim                 # A clean dark Neovim theme
    catppuccin-nvim                 # Soothing pastel theme for Neovim

    (vimUtils.buildVimPlugin {
      pname = "mini.icons"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-mini"; repo = "mini.icons";
        rev = "v0.16.0"; sha256 = "sha256-/sdLtMOOGeVvFDBB9N4CyUHpGXtUi1ZJ9dIpvxZ9C4Q="; };})

    # Intelligent pairing, better than mini.pairs
    # - configuration ./config/lua/plugins/0000-nvim-autopairs.lua
    # - does so intelligently with context awareness unlike the LazyVim's choice of mini.pairs
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "nvim-autopairs"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "windwp"; repo = "nvim-autopairs";
        rev = "7a2c97cccd60abc559344042fefb1d5a85b3e33b";
        sha256 = "sha256-cRIg1qO3WMxzcDQti0GEJl77KnlRCqyBN+g76PviWt0="; };})

    # Persistence is a simple lua plugin for automated session management.
    # - configuration ./config/lua/plugins/0000-persistence-nvim.lua
    # - saves active session under ~/.local/state/nvim/sessions on exit
    (vimUtils.buildVimPlugin {
      pname = "persistence.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "persistence.nvim";
        rev = "v3.1.0"; sha256 = "sha256-xZij+CYjAoxWcN/Z2JvJWoNkgBkz83pSjUGOfc9x8M0="; };})

    # # Installs and manages languages parsers and provides this syntax tree to other plugins
    # (vimUtils.buildVimPlugin {
    #   pname = "nvim-treesitter"; version = "2025-10-30";
    #   src = fetchFromGitHub { owner = "nvim-treesitter"; repo = "nvim-treesitter";
    #     rev = "42fc28ba918343ebfd5565147a42a26580579482";
    #     sha256 = "sha256-CVs9FTdg3oKtRjz2YqwkMr0W5qYLGfVyxyhE3qnGYbI="; };})
    #
    # # Builds on treesitter to provide context about your code objects
    # (vimUtils.buildVimPlugin {
    #   pname = "nvim-treesitter-context"; version = "2025-10-30";
    #   src = fetchFromGitHub { owner = "nvim-treesitter"; repo = "nvim-treesitter-context";
    #     rev = "ec308c7827b5f8cb2dd0ad303a059c945dd21969";
    #     sha256 = "sha256-QdZstxKsEILwe7eUZCmMdyLPyvNKc/e7cfdYQowHWPQ="; };})
    #
    # # Builds on treesitter to provide code navigation motions 
    # (vimUtils.buildVimPlugin {
    #   pname = "nvim-treesitter-textobjects"; version = "2025-10-30";
    #   src = fetchFromGitHub { owner = "nvim-treesitter"; repo = "nvim-treesitter-textobjects";
    #     rev = "5ca4aaa6efdcc59be46b95a3e876300cfead05ef";
    #     sha256 = "sha256-lf+AwSu96iKO1vWWU2D7jWHGfjXkbX9R2CX3gMZaD4M="; };})

    # Better comments and override support for treesitter languages
    # - configuration ./config/lua/plugins/0000-ts-comments-nvim.lua
    # - no external dependencies
    (vimUtils.buildVimPlugin {
      pname = "ts-comments.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "ts-comments.nvim";
        rev = "v1.5.0";
        sha256 = "sha256-nYdU5KlSSgxWgxu/EgpBUNDQ9zEXkEbiTkBO4ThHPfo="; };})

    # A snazy pure lua buffer line
    # - configuration ./config/lua/plugins/0100-bufferline-nvim.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "bufferline.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "akinsho"; repo = "bufferline.nvim";
        rev = "v4.9.1"; sha256 = "sha256-ae4MB6+6v3awvfSUWlau9ASJ147ZpwuX1fvJdfMwo1Q="; };})

    # Blazing fast neovim statusline written in pure lua
    # - configuration ./config/lua/plugins/0100-lualine-nvim.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "lualine.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-lualine"; repo = "lualine.nvim";
        rev = "3946f0122255bc377d14a59b27b609fb3ab25768";
        sha256 = "sha256-hdrAdG3hC2sAevQ6a9xizqPgEgnNKxuc5rBYn0pKM1c="; };})

    # Collection of plugins you enable in the configuration
    # - configuration ./config/lua/plugins/0100-snacks-nvim.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "snacks.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "snacks.nvim";
        rev = "v2.27.0"; sha256 = "sha256-QkcOKPgiJeA5LmQvC7DZ6ddjaoW8AE5I08Gm8jlEkT8="; };})

    # Pops up a window on different hot keys that shows keymaps as you are typing
    # - configuration ./config/lua/plugins/0100-which-key.lua
    # - depends on mini.icons
    (vimUtils.buildVimPlugin {
      pname = "which-key.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "which-key.nvim";
        rev = "v3.17.0"; sha256 = "sha256-kYpiw2Syu54B/nNVqTZeUHJIPNzAv3JpFaMWR9Ai3p4="; };})







    (vimUtils.buildVimPlugin {
      pname = "flash.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "flash.nvim";
        rev = "v2.1.0"; sha256 = "sha256-Qh9ty28xtRS3qXxE/ugx9FqAKrdeFGEf7W6yEORnZV8="; };})

    (vimUtils.buildVimPlugin {
      pname = "todo-comments.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "todo-comments.nvim";
        rev = "v1.4.0"; sha256 = "sha256-EH4Sy7qNkzOgA1INFzrtsRfD79TgMqSbKUdundyw22w="; };})


           # Utility

    #codecompanion-nvim
    #plenary-nvim
    #telescope-nvim
    #vim-startuptime
  ];

  # Build the plugins package for Neovim
  # - Packages are a named collection of plugins organized by purpose i.e. MODE=('start' | 'opt')
  # - Packages are in the `packpath` under `pack/$NAME/$MODE/{$PLUGIN_1...$PLUGIN_n}`
  # - Plugins under the `start` sub folder are automatically loaded by nvim on boot
  # - Plugins under `opt` are available to be loaded manually with `:packadd` from within nvim
  # - All .lua files in any pack/$NAME/start/$PLUGIN/plugin/ path will be automatically loaded
  # - Lua modules are looked for in any `lua` sub-folders in any path in the `runtimepath`
  # - Lua require calls reference the folder structure e.g. `require('a.b')` for `lua/a/b.lua`
  packName = "plugins";                     # can be anything
  pluginPath = runCommandLocal "nvim-plugins" {} ''
    mkdir -p $out/pack/${packName}/{start,opt}
    ln -vsfT ${./config/lua} $out/lua
    ln -vsfT ${./config/init} $out/pack/${packName}/start/init
    ${
      lib.concatMapStringsSep "\n"

      # Include the plugin with the appropriate folder structure
      (plugin: "ln -vsfT ${plugin} $out/pack/${packName}/opt/${lib.getName plugin}")

      # Plugins list to run through
      plugins
    }
  '';

  # Create a simple lua init script
  # Not using this in favor of my custom plugin ./config/init which loads ./config/lua/init.lua to
  # configure Nvim with all options, keymaps, plugins etc... instead of inline like it is here. The 
  # benefits are you get Lua syntax highlighting and full Lua module support which this inline here 
  # lacks.
  initLua = writeTextFile {
    name = "init.lua";
    text = ''
      vim.loader.enable(true)               -- Enable Lua bytecode cache at ~/.local/share/nvim/loader
    '';
  };

in 
  # symlinkJoin creates a new derivation that replaces all files in the given path with links where 
  # the files were moved to the store individually. This makes it easier to modify the original 
  # package while reusing its binaries to be efficient.
  symlinkJoin {
    name = "neovim-custom";                 # Package name being created
    paths = [neovim-unwrapped pluginPath];  # Paths being symlinked
    nativeBuildInputs = [makeWrapper];      # Build tools to make available during build

    # Wrap the target passing in custom arguments
    # - Nvim uses the term `pack` to refer to a collection of plugins
    # - NVIM_APPNAME defines a vim config namespace to isolate your configs from the host
    #   - essentially changes config lookup paths to `~/.config/${NVIM_APPNAME}`
    #   - this can be really useful if you want to test locally without picking up host settings
    # - Also create the alias links
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --add-flags '-u' \
        --add-flags '${initLua}' \
        --add-flags '--cmd' \
        --add-flags "'set packpath^=${pluginPath} | set runtimepath^=${pluginPath}'" \
        --set-default NVIM_APPNAME nvim-custom
      ln -s $out/bin/nvim $out/bin/vim
    '';

    # Make the plugins derivation available for build commands like
    # nix build -f ./direct.nix plugins
    passthru = {
      inherit pluginPath;
    };
  }
