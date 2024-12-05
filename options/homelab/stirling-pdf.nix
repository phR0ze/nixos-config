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
# - Stirling-PDF does not initiate any outbound calls for record-keeping or tracking purposes.
# - All files and PDFs exist either exclusively on the client side, server memory only during task 
#   execution, or as temporary files solely for the execution of the task.
#
# ### Deployment Features
# - App has outbound access to the internet
# - App is blocked from outbound connections to the LAN
# - App has dedicated podman bridge network with port forwarding to dedicated host macvlan
# - App is visiable on the LAN, with a dedicated host macvlan and static IP, for inbound connections
# - App data is persisted at /var/lib/$APP
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }: with lib.types;
let
  app = config.homelab.stirling-pdf;
in
{
  options = {
    homelab.stirling-pdf = {
      enable = lib.mkEnableOption "Deploy container based Stirling PDF";

      name = lib.mkOption {
        description = lib.mdDoc "App name to use for supporting components";
        type = types.str;
        default = "stirling-pdf";
      };

      nic = lib.mkOption {
        description = lib.mdDoc "Parent NIC for the app macvlan";
        type = types.str;
        default = "${args.settings.nic0}";
      };

      ip = lib.mkOption {
        description = lib.mdDoc "IP address to use for the app macvlan";
        type = types.str;
        default = "192.168.1.60";
      };

      port = lib.mkOption {
        description = lib.mdDoc "Port to use for Web Interface on the macvlan";
        type = types.port;
        default = 80;
        example = {
          port = 80;
        };
      };
    };
  };
 
  config = lib.mkIf app.enable {
    assertions = [
      {
        assertion = ("${app.nic}" != "");
        message = "Application parent NIC not specified, please set 'nic'";
      }
    ];

    # Create persistent directories for application
    systemd.tmpfiles.rules = [
      # type, path, mode, user, group, expiration
      # No group specified, i.e `-` defaults to root
      # No age specified, i.e `-` defaults to infinite
      "d /var/lib/${app.name} 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/customFiles 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/extraConfigs 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/logs 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/pipeline 0750 ${args.settings.username} - -"
      "d /var/lib/${app.name}/trainingData 0750 ${args.settings.username} - -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/frooodle/s-pdf:latest";
      autoStart = true;
      ports = [
        "${app.ip}:${toString app.port}:8080"
      ];
      volumes = [
        "/var/lib/${app.name}/customFiles:/customFiles:rw"
        "/var/lib/${app.name}/extraConfigs:/configs:rw"
        "/var/lib/${app.name}/logs:/logs:rw"
        "/var/lib/${app.name}/pipeline:/pipeline:rw"
        "/var/lib/${app.name}/trainingData:/usr/share/tessdata:rw"
      ];

      # Configure app via overrides
      environment = {
        "METRICS_ENABLED" = "false";                    # no need to track with homelab
        "SYSTEM_ENABLEANALYTICS" = "false";             # not a fan of being tracked
        "DOCKER_ENABLE_SECURITY" = "false";             # don't need to login with homelab
        "INSTALL_BOOK_AND_ADVANCED_HTML_OPS" = "false";
      };
      extraOptions = [
        "--network=${app.name}"
      ];
#      labels = {
#        "diun.enable" = "true";
#        "io.containers.autoupdate" = "registry";
#        "traefik.enable" = "true";
#        "traefik.http.services.pdf.loadbalancer.server.port" = "8080";
#      };
    };

    # Create host macvlan with a dedicated static IP for the app to port forward to
    networking = {
      macvlans.${app.name} = {
        interface = "${app.nic}";
        mode = "bridge";
      };
      interfaces.${app.name}.ipv4.addresses = [
        { address = "${app.ip}"; prefixLength = 32; }
      ];
      firewall.interfaces.${app.name}.allowedTCPPorts = [ 80 ];
    };

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app.name}" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f ${app.name}";
      };
      script = ''
        podman network inspect ${app.name} || podman network create ${app.name}
      '';
    };

    # Add additional configuration to the above generated app service unit i.e. acts as an overlay.
    # We simply match the name here that is autogenerated from the oci-container directive.
    systemd.services."podman-${app.name}" = {
      wantedBy = [ "multi-user.target" ];

      # Trigger the creation of the app macvlan if not already and wait for it. network-addresses... 
      # applies the static IP address to the macvlan which it waits to be created for, thus by 
      # waiting on it we ensure the macvlan is up and running with an IP address.
      wants = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];
      after = [
        "network-online.target"
        "network-addresses-${app.name}.service"
        "podman-network-${app.name}.service"
      ];

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app.name}";
      };
    };
  };
}
