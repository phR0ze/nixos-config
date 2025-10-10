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
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.nvim;
  x11 = config.system.x11;
  user = config.machine.user.name;

  configPath = "${./config}";
  pluginPath = import ./plugins.nix { inherit lib pkgs; };
in
{
  options = {
    apps.system.nvim = {
      enable = lib.mkEnableOption "Install and configure Nvim";
    };
  };

  config = lib.mkMerge [
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

          # Load the plugin manager
          packages.all.start = [ pkgs.vimPlugins.lz-n ];

          # Load the init.lua configuration file
          customLuaRC = ''
            vim.opt.rtp:prepend("${pluginPath}")
            vim.opt.rtp:prepend("${configPath}")
            dofile("${configPath}/init.lua")
          '';
        };
      };

      # Set environment variables
      environment.variables.EDITOR = "nvim";            # Set the editor to use
      environment.variables.VISUAL = "nvim";            # Set the editor to use
      environment.variables.KUBE_EDITOR = "nvim";       # Set the editor to use for Kubernetes edit commands

      # Install supporting packages
      environment.systemPackages = with pkgs; [
        stylua                                          # Opinionated Lua code formatter
      ];
    })
  ];
}
