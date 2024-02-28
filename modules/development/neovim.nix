# Neovim configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, lib, args, ... }:
{
  environment.systemPackages = with pkgs; [
    vimPlugins.nerdtree                 # 
    vimPlugins.vim-airline
    vimPlugins.vim-airline-themes
    vimPlugins.vim-deus
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ${
        pkgs.writeText "init.vim"
        (lib.fileContents ../../include/.config/nvim/init.vim)
      };
    };
  };
}

# vim:set ts=2:sw=2:sts=2
