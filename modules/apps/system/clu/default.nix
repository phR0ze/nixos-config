# clu
# 
# ### Purpose
# - Exposes clu configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
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
      clu
      git                                 # Fast distributed version control system
      jq                                   # Command line JSON processor, depof: kubectl
      psmisc                                # Proc filesystem utilities e.g. killall
      sops                                # Industry standard encryption at rest
    ];
  };
}
