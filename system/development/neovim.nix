# Neovim configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}

# vim:set ts=2:sw=2:sts=2
