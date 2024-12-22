# Stirling PDF configuration
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
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.homelab.stirling-pdf;
  app = config.homelab.stirling-pdf.app;
  appOpts = (import ../types/app.nix { inherit lib; }).appOpts;
in
{
  options = {
    homelab.stirling-pdf = {
      enable = lib.mkEnableOption "Deploy container based Stirling PDF";

      app = lib.mkOption {
        description = lib.mdDoc "Containerized app options";
        type = types.submodule appOpts;
        default = {
          name = "stirling-pdf";
          user = {
            name = machine.user.name;
            uid = config.users.users.${machine.user.name}.uid;
            gid = config.users.groups."users".gid;
          };
          nic = {
            name = config.networking.vnic0;
            ip = "192.168.1.57";
            port = 80;
          };
        };
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (app.name != null && app.name != "");
        message = "Application name not specified, please set 'app.name'"; }
      { assertion = (app.user.name != null && app.user.name != "");
        message = "Application user name not specified, please set 'app.user.name'"; }
      { assertion = (app.user.uid != null);
        message = "Application user uid not specified, please set 'app.user.uid'"; }
      { assertion = (app.user.gid != null);
        message = "Application user gid not specified, please set 'app.user.gid'"; }
      { assertion = (app.nic.name != null && app.nic.name != "");
        message = "Application nic name not specified, please set 'app.nic.name'"; }
      { assertion = (app.nic.ip != null);
        message = "Application nic ip not specified, please set 'app.nic.ip'"; }
      { assertion = (app.nic.port != null);
        message = "Application nic port not specified, please set 'app.nic.port'"; }
    ];

    # Requires podman virtualization to be configured
    virtualization.podman.enable = true;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app.name} 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/customFiles 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/extraConfigs 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/logs 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/pipeline 0750 ${toString app.user.uid} ${toString app.user.gid} -"
      "d /var/lib/${app.name}/trainingData 0750 ${toString app.user.uid} ${toString app.user.gid} -"
    ];

    # Generate the "podman-${app.name}" service unit for the container
    # https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
    virtualisation.oci-containers.containers."${app.name}" = {
      image = "docker.io/frooodle/s-pdf:latest";
      autoStart = true;
      hostname = "${app.name}";
      ports = [
        "${app.nic.ip}:${toString app.nic.port}:8080"
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
    };

    # Setup firewall exceptions
    networking.firewall.interfaces."${app.name}".allowedTCPPorts = [ app.nic.port ];

    # Create host macvlan with a dedicated static IP for the app to port forward to
    networking = {
      macvlans.${app.name} = {
        interface = "${app.nic.name}";
        mode = "bridge";
      };
      interfaces.${app.name}.ipv4.addresses = [
        { address = "${app.nic.ip}"; prefixLength = 32; }
      ];
    };

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app.name}" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = [
          "podman network rm -f ${app.name}"
        ];
      };
      script = ''
        if ! podman network exists ${app.name}; then
          podman network create ${app.name}
        fi
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
