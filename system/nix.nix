# Nix configuration
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
#  nixpkgs = {
#    overlays =
#      builtins.attrValues outputs.overlays
#      ++ [
#        inputs.nixneovimplugins.overlays.default
#        inputs.nur.overlay
#        inputs.neovim-nightly-overlay.overlay
#        inputs.nixgl.overlay
#        inputs.codeium.overlays."x86_64-linux".default
#      ];
#
#    config = {
#      allowUnfree = true;
#      allowUnfreePredicate = _: true;
#    };
#  };

  nix = {
    package = pkgs.nixFlakes;
    settings = {
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ]; # enable flake support
    };
    extraOptions = "experimental-features = nix-command flakes";
  };
}

# vim:set ts=2:sw=2:sts=2
