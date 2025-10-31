# Neovim configuration
#
# ### References
# - [Lazyvim Nix](https://github.com/jla2000/lazyvim-nix)
# - [Nvim-bundle](https://github.com/jla2000/nvim-bundle)
# - [Neovim Wrapper](https://ayats.org/blog/neovim-wrapper)
#
# ### Details
# - All plugins are built and stored in the nix store
# - Configuration is all written in lua
# - Plugins are lazy loaded using lz.n
#---------------------------------------------------------------------------------------------------
{
  neovim-unwrapped, symlinkJoin, fetchFromGitHub, makeWrapper, runCommandLocal, vimPlugins, vimUtils, 
  writeTextFile, lib,
}: let

  # Plugins to have loaded on boot
  # - End up in ./result/pack/plugins/start
  startPlugins = with vimPlugins; [
    #snacks-nvim                     # Collection of lua modules
  ];

  # Plugins to make available but don't load on boot.
  # - These will be lazy loaded by lz-n as needed based on triggers
  # - End up in ./result/pack/plugins/opt
  optPlugins = with vimPlugins; [
    lz-n                            # Light weight lazy plugin loader

    # Colorschemes
    vim-deus                        # Color scheme I've used for years
    gruvbox-nvim                    # Lua port of the most famous vim colorscheme
    tokyonight-nvim                 # A clean dark Neovim theme
    catppuccin-nvim                 # Soothing pastel theme for Neovim 

    # Coding
    (vimUtils.buildVimPlugin {      # Intelligent pairing, better than mini.pairs
      pname = "nvim-autopairs"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "windwp"; repo = "nvim-autopairs";
        rev = "7a2c97cccd60abc559344042fefb1d5a85b3e33b";
        sha256 = "sha256-cRIg1qO3WMxzcDQti0GEJl77KnlRCqyBN+g76PviWt0="; };})

    # Editor
    (vimUtils.buildVimPlugin {      # Shows available keybindings in a popup as you type
      pname = "which-key.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "which-key.nvim";
        rev = "v3.17.0"; sha256 = "sha256-kYpiw2Syu54B/nNVqTZeUHJIPNzAv3JpFaMWR9Ai3p4="; };})

    # UI
    (vimUtils.buildVimPlugin {      # Replacement icons for nvim-web-devicons
      pname = "mini.icons"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-mini"; repo = "mini.icons";
        rev = "v0.16.0"; sha256 = "sha256-/sdLtMOOGeVvFDBB9N4CyUHpGXtUi1ZJ9dIpvxZ9C4Q="; };})

    (vimUtils.buildVimPlugin {      # Collection of quality of life plugins
      pname = "snacks.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "folke"; repo = "snacks.nvim";
        rev = "v2.27.0"; sha256 = "sha256-QkcOKPgiJeA5LmQvC7DZ6ddjaoW8AE5I08Gm8jlEkT8="; };})

    (vimUtils.buildVimPlugin {      # Blazing fast neovim statusline written in pure lua
      pname = "lualine.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "nvim-lualine"; repo = "lualine.nvim";
        rev = "3946f0122255bc377d14a59b27b609fb3ab25768";
        sha256 = "sha256-hdrAdG3hC2sAevQ6a9xizqPgEgnNKxuc5rBYn0pKM1c="; };})

    (vimUtils.buildVimPlugin {      # A snazzy bufferline for Neovim 
      pname = "bufferline.nvim"; version = "2025-10-30";
      src = fetchFromGitHub { owner = "akinsho"; repo = "bufferline.nvim";
        rev = "v4.9.1"; sha256 = "sha256-ae4MB6+6v3awvfSUWlau9ASJ147ZpwuX1fvJdfMwo1Q="; };})

    # Utility
    #(vimUtils.buildVimPlugin {      # Toggle a terminal window inside Neovim
    #  pname = "toggleterm-nvim"; version = "2025-10-30";
    #  src = fetchFromGitHub { owner = "akinsho"; repo = "toggleterm.nvim";
    #    rev = "v2.13.1";
    #    sha256 = "sha256-Xc3TZUA6glsuchignUSk4gLZs1IBvI+YnWeP1r+snbQ="; };})

    #codecompanion-nvim
    #plenary-nvim 
    #telescope-nvim
    #vim-startuptime                               # 
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
      (x: "ln -vsfT ${x.plugin} $out/pack/${packName}/${x.mode}/${lib.getName x.plugin}")

      # Combine the plugin lists while tracking the mode
      (map (x: { plugin = x; mode = "start"; }) startPlugins
       ++ map (x: { plugin = x; mode = "opt"; }) optPlugins)
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
