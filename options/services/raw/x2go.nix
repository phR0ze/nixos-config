# x2go configuration
#
# ### Client connection
# x2goclient --debug 1> /tmp/x2goclient.stdout.log 2>  /tmp/x2goclient.stderr.log
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.x2go;
  machine = config.machine;
in
{
  options = {
    services.raw.x2go = {
      enable = lib.mkEnableOption "Install and configure";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [
        x2goserver
    ];

    services.x2goserver = {
      enable = true;
      #settings = 
    };
    networking.firewall.interfaces.allowedTCPPorts = [ 5900 ];
  };
}
