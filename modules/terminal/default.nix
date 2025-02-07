{ ... }:
{
  imports = [
    ./env.nix
    ./bash.nix
    ./git.nix
    ./starship.nix
  ];

  files.all.".dircolors".copy = ../../include/home/.dircolors;
}
