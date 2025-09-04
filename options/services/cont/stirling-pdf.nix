# Stirling PDF configuration
# - https://docs.stirlingpdf.com/
# - https://github.com/Stirling-Tools/Stirling-PDF
# - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-apps/stirling-pdf.nix
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
# - Get status with: `systemctl status podman-stirling-pdf`
# - UI accessible at ???
# - App has outbound access to the internet
# - App is blocked from outbound connections to the LAN
# - App has dedicated podman bridge network with port forwarding to dedicated host macvlan
# - App is visiable on the LAN, with a dedicated host macvlan and static IP, for inbound connections
# - App data is persisted at /var/lib/$APP
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.stirling-pdf;

  # Configure service argument defaults
  app = "stirling-pdf";
  filtered = builtins.filter (x: x.name == app && (!x ? "type" || x.type == "cont")) args.services or [];
  service = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else { nic = {}; port = 80; };
  defaults = service // { user = { name = app; group = app; uid = 1001; gid = 1001; }; };
in
{

  options = {
    services.cont.stirling-pdf = lib.mkOption {
      description = lib.mdDoc "Stirling PDF service options";
      type = types.submodule {
        options = {
          #tag = lib.mkEnableOption "Image tag to use for the service";
        };
        imports = [
          (import ../../types/service.nix { inherit lib defaults; })
        ];
      };
      default = defaults;
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      # Debug assertion
      #{ assertion = (args.user.name == null);
      #  message = "echo '${builtins.toJSON cfg}' | jq"; }

      { assertion = (machine.net.bridge.enable);
        message = "Requires 'machine.net.bridge.enable = true;' to work correctly"; }
      { assertion = (cfg ? "nic" && cfg.nic ? "link" && cfg.nic.link != "");
        message = "Requires '${app}.nic.link' => '${builtins.toJSON cfg.nic.link}' be set to the bridge name"; }
      { assertion = (cfg ? "nic" && cfg.nic ? "ip" && cfg.nic.ip != "");
        message = "Requires '${app}.nic.ip' => '${builtins.toJSON cfg.nic.ip}' be set to a static IP address"; }
      { assertion = (cfg ? "port" && cfg.port > 0);
        message = "Requires '${app}.port' => '${builtins.toJSON cfg.nic.ip}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "name" && cfg.user.name != null && cfg.user.name != "");
        message = "Requires '${app}.user.name' => '${builtins.toJSON cfg.user.name}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "group" && cfg.user.group != null && cfg.user.group != "");
        message = "Requires '${app}.user.group' => '${builtins.toJSON cfg.user.group}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "uid" && cfg.user.uid != null && cfg.user.uid > 0);
        message = "Requires '${app}.user.uid' => '${builtins.toJSON cfg.user.uid}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "gid" && cfg.user.gid != null && cfg.user.gid > 0);
        message = "Requires '${app}.user.gid' => '${builtins.toJSON cfg.user.gid}' be set"; }
    ];

    # Requires podman virtualization to be configured
    virtualisation.podman.enable = true;

    # Create app user to run the container as for extra security
    users.users.${cfg.user.name} = {
      uid = cfg.user.uid;
      isSystemUser = true;
      group = cfg.user.group;
      home = "/var/empty";
    };
    users.groups.${cfg.user.group} = {
      gid = cfg.user.gid;
    };

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${app} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${app}/trainingData 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${app}/extraConfigs 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${app}/customFiles 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${app}/logs 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${app}/pipeline 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${app}" service unit for the container
    # https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
    virtualisation.oci-containers.containers."${app}" = {
      image = "docker.stirlingpdf.com/stirlingtools/stirling-pdf:${cfg.tag}";
      autoStart = true;
      hostname = "${app}";
      ports = [
        "${(f.toIP cfg.nic.ip).address}:${toString cfg.port}:8080"
      ];
      volumes = [
        "/var/lib/${app}/trainingData:/usr/share/tessdata:rw"
        "/var/lib/${app}/extraConfigs:/configs:rw"
        "/var/lib/${app}/customFiles:/customFiles:rw"
        "/var/lib/${app}/logs:/logs:rw"
        "/var/lib/${app}/pipeline:/pipeline:rw"
      ];

      # Configure app via overrides
      environment = {
        "METRICS_ENABLED" = "false";                    # no need to track with homelab
        "SYSTEM_ENABLEANALYTICS" = "false";             # not a fan of being tracked
        "DOCKER_ENABLE_SECURITY" = "false";             # don't need to login with homelab
        "DISABLE_ADDITIONAL_FEATURES" = "false";        # don't lock off other features
        "INSTALL_BOOK_AND_ADVANCED_HTML_OPS" = "false"; # ??
      };
      extraOptions = [
        "--network=${app}"
      ];
    };

    # Setup firewall exceptions
    networking.firewall.interfaces."${app}".allowedTCPPorts = [ cfg.port ];

    # Create host macvlan with a dedicated static IP for the app to port forward to
    # - see new macvlan interface `stirling-pdf@br0` with `ip a`
    # - sudo systemctl status network-addresses-stirling-pdf.service
    networking = {
      macvlans.${app} = {
        interface = "${cfg.nic.link}";
        mode = "bridge";
      };
      interfaces.${app}.ipv4.addresses = [ (f.toIP cfg.nic.ip)];
    };

    # Create a dedicated container network to keep the app isolated from other services
    systemd.services."podman-network-${app}" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = [
          "podman network rm -f ${app}"
        ];
      };
      script = ''
        if ! podman network exists ${app}; then
          podman network create ${app}
        fi
      '';
    };

    # Add additional configuration to the above generated app service unit i.e. acts as an overlay.
    # We simply match the name here that is autogenerated from the oci-container directive.
    systemd.services."podman-${app}" = {
      wantedBy = [ "multi-user.target" ];

     # Trigger the creation of the app macvlan if not already and wait for it. network-addresses... 
      # applies the static IP address to the macvlan which it waits to be created for, thus by 
      # waiting on it we ensure the macvlan is up and running with an IP address.
      wants = [
        "network-online.target"
        "network-addresses-${app}.service"
        "podman-network-${app}.service"
      ];
      after = [
        "network-online.target"
        "network-addresses-${app}.service"
        "podman-network-${app}.service"
      ];

      serviceConfig = {
        Restart = "always";
        WorkingDirectory = "/var/lib/${app}";
      };
    };
  };
}
