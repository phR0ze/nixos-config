# clu
# 
# ### Purpose
# - Exposes clu configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.system.clu;
in
{
  options = {
    apps.system.clu = {
      enable = lib.mkEnableOption "Install and configure clu";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Flake overlay exists now
      pkgs.clu
      #(pkgs.callPackage ./clu.nix {})
    ];
  };
}
