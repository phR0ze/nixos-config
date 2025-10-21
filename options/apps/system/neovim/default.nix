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
  startPlugins = with vimPlugins; [
    snacks-nvim                                   # Collection of lua modules
  ];

  # Plugins to make available but don't load on boot
  # These will be lazy loaded by lz-n as needed based on triggers
  optPlugins = with vimPlugins; [
    lz-n

    # Colorschemes
    vim-deus
    gruvbox-nvim
    tokyonight-nvim

    #codecompanion-nvim
    #plenary-nvim 
    #telescope-nvim
    #vim-startuptime                               # 
    which-key-nvim                                # Shows available keybindings in a popup as you type
    (vimUtils.buildVimPlugin {                    # 
      pname = "mini-pairs"; version = "2025-10-08";
      src = fetchFromGitHub { owner = "nvim-mini"; repo = "mini.pairs";
        rev = "b9aada8c0e59f2b938e98fbf4eae0799eba96ad9";
        sha256 = "sha256-KFWpyITaKc9AGhvpLkeq9B3a5MELqed2UBo9X8oC6Ac="; };})
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
