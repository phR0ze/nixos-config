# Nvim configuration
#
# ### References
# - [Lazyvim Nix](https://github.com/jla2000/lazyvim-nix)
# - [Nvim-bundle](https://github.com/jla2000/nvim-bundle)
# - [Neovim Wrapper](https://ayats.org/blog/neovim-wrapper)
#
# ### Details
# - All plugins are built from nixpkgs
# - Configuration is all written in lua
# - Plugins are lazy loaded using lz.n
# - Lua config can be changed at runtime
#---------------------------------------------------------------------------------------------------
{
  # Target package being wrapped
  neovim-unwrapped,

  # symlinkJoin creates a new derivation that replaces all files in the given path with links where 
  # the files were moved to the store individually. This makes it easier to modify the original 
  # package while reusing its binaries to be efficient.
  symlinkJoin,

  # Other tools
  makeWrapper, runCommandLocal, vimPlugins, writeTextFile, lib,
}: let

  # Custom nvim package name, can be anything
  packName = "plugins";

  # Plugins to have loaded on boot
  startPlugins = with vimPlugins; [
    lz-n
  ];

  # Plugins to make available but don't load on boot
  # These will be lazy loaded by lz-n as needed based on triggers
  optPlugins = with vimPlugins; [
    plenary-nvim 
    telescope-nvim
    vim-startuptime                               # 
    which-key-nvim                                # Shows available keybindings in a popup as you type
  ];
  
  # Build the plugins package with all plugins under `pack/plugins` folder
  # - Nvim uses the term `pack` to refer to a collection of plugins and it is required
  pluginPath = runCommandLocal "nvim-plugins" {} ''
    mkdir -p $out/pack/${packName}/{start,opt}
    ln -vsfT ${./config/lua} $out/lua
    ln -vsfT ${./config/init.nvim} $out/pack/${packName}/start/init.nvim

    ${
      lib.concatMapStringsSep "\n"

      # Include the plugin with the appropriate folder structure
      (x: "ln -vsfT ${x.plugin} $out/pack/${packName}/${x.mode}/${lib.getName x.plugin}")

      # Combine the plugin lists while tracking the mode
      (map (x: { plugin = x; mode = "start"; }) startPlugins
       ++ map (x: { plugin = x; mode = "opt"; }) optPlugins)
    }
  '';

  # Create a simple lua init script load my custom configuration plugin
  initLua = writeTextFile {
    name = "init.lua";
    text = ''
      vim.loader.enable(true)               -- Enable Lua bytecode cache at ~/.local/share/nvim/loader
    '';
  };
in 
  symlinkJoin {
    name = "neovim-custom";                 # Package name being created
    paths = [neovim-unwrapped pluginPath];  # Paths being symlinked
    nativeBuildInputs = [makeWrapper];      # Build tools to make available during build

    # Wrap the target passing in custom arguments
    # - Nvim uses the term `pack` to refer to a collection of plugins
    # - NVIM_APPNAME defines a vim config namespace to isolation your configs from the host
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --add-flags '-u' \
        --add-flags '${initLua}' \
        --add-flags '--cmd' \
        --add-flags "'set packpath^=${pluginPath} | set runtimepath^=${pluginPath}'" \
        --set-default NVIM_APPNAME nvim-custom
    '';

    # Make the plugins derivation available for build commands like
    # nix build -f ./direct.nix plugins
    passthru = {
      inherit pluginPath;
    };
  }
