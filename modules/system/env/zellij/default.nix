# Zellij configuration
#
# ### Details
# Terminal multiplexer, used in place of tmux.
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:

let
  cfg = config.system.env.zellij;
in
{
  options = {
    system.env.zellij = {
      enable = lib.mkEnableOption "Install and configure Zellij terminal multiplexer";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      zellij
    ];
  };
}
