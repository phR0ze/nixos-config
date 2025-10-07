# mini.pairs
#
# Automatically inserts a matching closing character when you type an opening character like ", [, or (.
# 
# ### References
# - [mini.pairs](https://github.com/nvim-mini/mini.pairs)
# - Part of the [LazyVim](https://www.lazyvim.org/plugins/coding)
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  pname = "mini-pairs";
  version = "2023-10-06";
  src = pkgs.fetchFromGitHub {
    owner = "nvim-mini";
    repo = "mini.pairs";
    rev = "b327d6a5b7e4cbe88f5e7398a4ecceaf2b015d73";
    sha256 = "sha256-...";  # Replace with actual hash
  };
};

in pkgs.neovim.override {
  configure = {
    customRC = ''
      lua << EOF
      require('mini.pairs').setup()
      EOF
    '';
    packages.myPlugins = with pkgs.vimPlugins; {
      start = [ miniPairs ];
    };
  };
}
