# Stirling PDF configuration
# - https://docs.stirlingpdf.com/
# - https://github.com/Stirling-Tools/Stirling-PDF
# - [Environment vars](https://github.com/Stirling-Tools/Stirling-PDF#customisatio)
#
# ### Description
# Stirling PDF is a robust, locally hosted web-based PDF manipulation tool. It enables you to carry 
# out various operations on PDF files, including splitting, merging, converting, reorganizing, adding 
# images, rotating, compressing, and more. This locally hosted web service has evolved to 
# encompass a comprehensive set of features, addressing all your PDF requirements.
#
# - Stirling-PDF does not initiate any outbound calls for record-keeping or tracking purposes.
# - All files and PDFs exist either exclusively on the client side, server memory only during task 
#   execution, or as temporary files solely for the execution of the task.
#
# ### Deployment Features
# - Service has outbound access to the internet
# - Service is blocked from outbound connections to the LAN
# - Service has dedicated podman bridge network with port forwarding to dedicated host macvlan
# - Service is visible on the LAN, with a dedicated host macvlan and static IP, for inbound connections
# - Service data is persisted at /var/lib/$SERVICE
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.nspawn.stirling-pdf;

  filtered = builtins.filter (x: x.name == "stirling-pdf") machine.services;
  defaults = if (builtins.length filtered > 0) then builtins.elemAt filtered 0 else {};
in
{
  options = {
    services.nspawn.stirling-pdf = {
      enable = lib.mkEnableOption "Deploy nspawn container based Stirling PDF";
      opts = lib.mkOption {
        description = lib.mdDoc "Containerized service options";
        type = types.submodule (import ../../types/service.nix { inherit lib; });
        default = defaults;
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (builtins.length filtered > 0);
        message = "Requires 'machine.services' contain a config for this service"; }
      { assertion = (machine.net.bridge.enable);
        message = "Requires 'machine.net.bridge.enable = true;' to work correctly"; }
      { assertion = (cfg.opts.nic.link != "");
        message = "Requires 'opts.nic.link' be set to the bridge name"; }
      { assertion = (cfg.opts.nic.ip != "");
        message = "Requires 'opts.nic.ip' be set to a static IP address"; }
      { assertion = (cfg.opts.port != 0); message = "Requires 'opts.port' be set"; }
    ];

    # Host configuration for service
    networking.firewall.enable = false;
    #networking.firewall.allowedTCPPorts = [ cfg.opts.port ];

    # Container configuration for service
    containers.stirling-pdf = {
      autoStart = true;                     # Enable the systemd unit to be started on boot
      privateNetwork = true;                # Bind to local host bridge to get a presence on the LAN
      hostBridge = cfg.opts.nic.link;       # Host bridge name to bind to e.g. br0
      localAddress = cfg.opts.nic.ip;       # Static IP for the virtual adapter on the bridge

      config = { config, pkgs, lib, ...}: {
        system.stateVersion = machine.nix.minVer;

        services.stirling-pdf = {
          enable = true;
          environment = {
            SERVER_PORT = cfg.opts.port;                  # set the port to serve the service on
            METRICS_ENABLED = "false";                    # no need to track with homelab
            SYSTEM_ENABLEANALYTICS = "false";             # not a fan of being tracked
            DOCKER_ENABLE_SECURITY = "false";             # don't need to login with homelab
            INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "false"; # installs calibre when true
          };
        };

        # Allow the server port through the firewall
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [ cfg.opts.port ];
      };
    };
  };
}
