# Zellij configuration
#
# ### Details
# Terminal multiplexer, used in place of tmux.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  cfg = config.apps.system.zellij;
in
{
  options = {
    apps.system.zellij = {
      enable = lib.mkEnableOption "Install and configure Zellij terminal multiplexer";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      zellij
    ];
  };
}
