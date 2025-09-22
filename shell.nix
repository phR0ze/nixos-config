# Nix Shells are good for simple experiments to test your packages
# - print output e.g. during install with: ${pkgs.tree}/bin/tree .
# - run with: nix-shell
let
  pkgs = import <nixpkgs> {};
  kasmvnc = pkgs.callPackage ./packages/kasmvnc {};
in
  pkgs.mkShell {
    packages = [ kasmvnc ];
  }
