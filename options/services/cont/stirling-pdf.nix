# Stirling PDF configuration
# - https://docs.stirlingpdf.com/
# - https://github.com/Stirling-Tools/Stirling-PDF
# - [Environment vars](https://github.com/Stirling-Tools/Stirling-PDF#customisatio)
#
# ### Description
# Stirling PDF is a robust, locally hosted web-based PDF manipulation tool. It enables you to carry 
# out various operations on PDF files, including splitting, merging, converting, reorganizing, adding 
# images, rotating, compressing, and more. This locally hosted web application has evolved to 
# encompass a comprehensive set of features, addressing all your PDF requirements.
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
{ config, lib, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.stirling-pdf;
  appOpts = import ../../types/app.nix { inherit lib; };
in
{
  options = {
    services.cont.stirling-pdf = {
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
            link = machine.net.bridge.name;
            ip = { full = "192.168.1.51/24"; attrs = { address = ""; prefixLength = 24; }; };
          };
          port = 80;
        };
      };
    };
  };
 
  config = lib.mkIf cfg.enable {
    assertions = [
      { assertion = (machine.net.bridge.enable);
        message = "Requires 'machine.net.bridge.enable = true;' to work correctly"; }
      { assertion = (cfg.app.nic.link != "");
        message = "Requires 'app.nic.link' be set to the bridge name"; }
      { assertion = (cfg.app.nic.ip.full != "");
        message = "Requires 'app.nic.ip.full' be set to a static IP address"; }
    ];

    containers.stirling-pdf = {
      autoStart = true;                     # Enable the systemd unit to be started on boot
      privateNetwork = true;                # Bind to local host bridge to get a presence on the LAN
      hostBridge = cfg.app.nic.link;        # Host bridge name to bind to e.g. br0
      localAddress = cfg.app.nic.ip.full;   # Static IP for the virtual adapter on the bridge

      config = { config, pkgs, lib, ...}: {
        system.stateVersion = machine.nix.minVer;

        services.stirling-pdf = {
          enable = true;
          environment = {
            SERVER_PORT = cfg.app.port;                   # set the port to serve the app on
            METRICS_ENABLED = "false";                    # no need to track with homelab
            SYSTEM_ENABLEANALYTICS = "false";             # not a fan of being tracked
            DOCKER_ENABLE_SECURITY = "false";             # don't need to login with homelab
            INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "false"; # installs calibre when true
          };
        };

        # Allow the server port through the firewall
        networking.firewall.allowedTCPPorts = [ cfg.app.port ];
      };
    };
  };
}
