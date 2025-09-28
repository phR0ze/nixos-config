# Selkies
#

{ config, lib, pkgs, args, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.raw.selkies;

  selkies = pkgs.python312Packages.callPackage ../../../packages/selkies {};
in
{
  options = {
    services.raw.selkies = {
      enable = lib.mkEnableOption "Install and configure selkies";
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Install the actual package
    environment.systemPackages = [ selkies ];

    # Configure firewall exceptions
    networking.firewall.enable = false;
    services.raw.rustdesk.enable = lib.mkForce false;
    #networking.firewall.interfaces.allowedTCPPorts = [ 8080 ];

#    systemd.user.services."selkies" = {
#      enable = true;
#      description = "Selkies gstreamer service to stream the X server once it starts";
#      environment = config.environment.variables;
#      after = [ "network.target" "pulseaudio.service" ];
#      requires = [ "pulseaudio.service" ];
#
#      serviceConfig = {
#          Type = "simple";
#          Restart = "always";
#          RestartSec = 5;
#          CPUWeight = 500;
#      };
#
#      script = ''
#      "${cfg.services.userValidationScript}/bin/script" || exit 0
#      ${pkgs.bash}/bin/bash -c "if [ ! $(echo ''${ENV_NOVNC_ENABLE} | ${pkgs.coreutils}/bin/tr '[:upper:]' '[:lower:]') ]; then ${entrypoint}/bin/script; else sleep infinity; fi"
#      '';
#
#      wantedBy = [ "default.target" ];
#    };
  };
}
