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
  defaults = f.getService args "stirling-pdf" 2001 2001;
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.cont.stirling-pdf = lib.mkOption {
      description = lib.mdDoc "Stirling PDF service options";
      type = types.submodule {
        options = {
          #other = lib.mkEnableOption "Service specific option";
        };
        imports = [
          (import ../../types/service.nix { inherit lib defaults; })
        ];
      };
      default = defaults;
    };
  };
 
  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;
    users.users.${cfg.user.name} = f.createContUser cfg.user;
    users.groups.${cfg.user.group} = f.createContGroup cfg.user;

    # Create persistent directories for application
    # - Args: type, path, mode, user, group, expiration
    # - No group specified, i.e `-` defaults to root
    # - No age specified, i.e `-` defaults to infinite
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name}/trainingData 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/extraConfigs 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/customFiles 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/logs 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/pipeline 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    # https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
    virtualisation.oci-containers.containers."${cfg.name}" = {
      # [Non-root isn't supported](https://github.com/Stirling-Tools/Stirling-PDF/issues/508)
      # user = "${toString cfg.user.uid}:${toString cfg.user.gid}";
      image = "docker.stirlingpdf.com/stirlingtools/stirling-pdf:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      ports = [ "${(f.toIP config.net.primary.ip).address}:${toString cfg.port}:8080" ];
      volumes = [
        "/var/lib/${cfg.name}/trainingData:/usr/share/tessdata:rw"
        "/var/lib/${cfg.name}/extraConfigs:/configs:rw"
        "/var/lib/${cfg.name}/customFiles:/customFiles:rw"
        "/var/lib/${cfg.name}/logs:/logs:rw"
        "/var/lib/${cfg.name}/pipeline:/pipeline:rw"
      ];

      # Configure app via overrides
      environment = {
        "PUID" = "${toString cfg.user.uid}";            # set the user to run as
        "PGID" = "${toString cfg.user.gid}";            # set the group to run as
        "METRICS_ENABLED" = "false";                    # no need to track with homelab
        "SYSTEM_ENABLEANALYTICS" = "false";             # not a fan of being tracked
        "DOCKER_ENABLE_SECURITY" = "false";             # don't need to login with homelab
        "DISABLE_ADDITIONAL_FEATURES" = "false";        # don't lock off other features
        "INSTALL_BOOK_AND_ADVANCED_HTML_OPS" = "false"; # ??
      };
      extraOptions = [
        "--network=${cfg.name}"
      ];
    };

    networking.firewall.interfaces.${machine.net.bridge.name}.allowedTCPPorts = [ cfg.port ];

    # Create podmane network and extend service to use it
    systemd.services."podman-network-${cfg.name}" = f.createContNetwork cfg.name;
    systemd.services."podman-${cfg.name}" = f.extendContService cfg.name;
  };
}
