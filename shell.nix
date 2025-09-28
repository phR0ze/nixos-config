# Nix Shells are good for simple experiments to test your packages
# - print output e.g. during install with: ${pkgs.tree}/bin/tree .
# - run with: nix-shell
let
  pkgs = import <nixpkgs> { config = { allowUnfree = true; }; };
  kasmvnc = pkgs.callPackage ./packages/kasmvnc {};
  selkies = pkgs.python312Packages.callPackage ./packages/selkies {};
in
  pkgs.mkShell {
    packages = [ selkies ];
  }
