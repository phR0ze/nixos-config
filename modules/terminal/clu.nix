# clu configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:

# Writing NixOS Modules
# https://nixos.org/manual/nixos/unstable/#sec-writing-modules
let
  clu = pkgs.writeShellScriptBin "foobar" ''
    echo "hello foobar"
  '';
in {
  environment.systemPackages = [ clu ];
}
