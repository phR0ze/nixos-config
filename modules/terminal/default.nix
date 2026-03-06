{ ... }:
{
  imports = [
    ./env.nix
    ./bash.nix
    ./git.nix
  ];

  files.all.".dircolors".copy = ../../include/home/.dircolors;
}
