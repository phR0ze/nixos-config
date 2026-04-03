{ ... }:
{
  imports = [
    ./env.nix
    ./bash.nix
  ];

  files.all.".dircolors".copy = ../../include/home/.dircolors;
}
