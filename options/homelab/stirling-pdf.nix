# Stirling PDF home configuration
# - https://docs.stirlingpdf.com/
# - https://github.com/Stirling-Tools/Stirling-PDF
#
# ### Description
# Stirling PDF is a robust, locally hosted web-based PDF manipulation tool using Docker. It enables 
# you to carry out various operations on PDF files, including splitting, mergin, converting, 
# reorganizing, adding images, rotating, compressing, and more. This locally hosted web application 
# has evolved to encompass a comprehensive set of features, addressing all your PDF requirements.
#
# - Web Interface
# - Stirling-PDF does not initiate any outbound calls for record-keeping or tracking purposes.
# - All files and PDFs exist either exclusively on the client side, server memory only during task 
#   execution, or as temporary files solely for the execution of the task.
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  cfg = config.homelab.stirling-pdf;
  app = "stirling-pdf";
in
{
  options = {
    homelab.stirling-pdf = {
      enable = lib.mkEnableOption "Deploy container based Stirling PDF";

      port = lib.mkOption {
        description = lib.mdDoc "Port to use for Web Interface.";
        type = types.port;
        default = 80;
        example = {
          port = 80;
        };
      };
    };
  };
 
  config = lib.mkIf cfg.enable {

    # Generate the "podman-${app}" service unit for the container
    # https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
    virtualisation.oci-containers.containers."${app}" = {
      image = "docker.io/frooodle/s-pdf:latest";
      autoStart = true;
      ports = [
        "${toString cfg.port}:8080"
      ];
      volumes = [
        "/var/lib/${app}/customFiles:/customFiles:rw"
        "/var/lib/${app}/extraConfigs:/configs:rw"
        "/var/lib/${app}/logs:/logs:rw"
        "/var/lib/${app}/pipeline:/pipeline:rw"
        "/var/lib/${app}/trainingData:/usr/share/tessdata:rw"
      ];
#      environment = {
#        "DOCKER_ENABLE_SECURITY" = "false";
#        "INSTALL_BOOK_AND_ADVANCED_HTML_OPS" = "false";
#        "LANGS" = "en_US";
#      };
#      environmentFiles = [
#        default.env
#      ];
#      extraOptions = [
#        "--network-alias=stirling-pdf"
#        "--network=stirling-pdf_default"
#      ];
#      labels = {
#        "diun.enable" = "true";
#        "io.containers.autoupdate" = "registry";
#        "traefik.enable" = "true";
#        "traefik.http.services.pdf.loadbalancer.server.port" = "8080";
#      };
    };

    # Open up firewall on host for new app service
    networking.firewall.allowedTCPPorts = [ 80 ];

    # Create persistent directories for application
    systemd.tmpfiles.rules = [
      # type, path, mode, user, group, expiration
      # No group specified, i.e `-` defaults to root
      "d /var/lib/${app} 0750 ${args.settings.username} - -"
      "d /var/lib/${app}/customFiles 0750 ${args.settings.username} - -"
      "d /var/lib/${app}/extraConfigs 0750 ${args.settings.username} - -"
      "d /var/lib/${app}/logs 0750 ${args.settings.username} - -"
      "d /var/lib/${app}/pipeline 0750 ${args.settings.username} - -"
      "d /var/lib/${app}/trainingData 0750 ${args.settings.username} - -"
    ];

    # Add additional configuration to the above generated app service unit
    systemd.services."podman-${app}" = {
      #wantedBy = [ "multi-user.target" ];
      #wants = [ "network-online.target" ];
      #after = [ "network-online.target" ];
#      environment = {
#        "XDG_DATA_HOME" = "/var/lib/${app}/data";
#        "XDG_CACHE_HOME" = "/var/lib/${app}/cache";
#        "XDG_CONFIG_HOME" = "/var/lib/${app}/config";
#      };
      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app}";

        # Hardening
        # https://docs.rockylinux.org/guides/security/systemd_hardening/
        #CapabilityBoundingSet = "";
      };
    };
  };
}
