# Stirling PDF home configuration
# - https://docs.stirlingpdf.com/
# - https://github.com/Stirling-Tools/Stirling-PDF
#
# ### Installation
# - Full docker images offers more features
# - https://docs.stirlingpdf.com/Getting%20started/Installation/Docker/Docker%20Install
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
in
{
  options = {
    homelab.stirling-pdf = {
      enable = lib.mkEnableOption "Deploy Stirling PDF";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    virtualisation.oci-containers.containers."stirling-pdf" = {
      image = "docker.io/frooodle/s-pdf:latest";
#      volumes = [
#        "/workload/appdata/pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata:rw"
#        "/workload/appdata/pdf/extraConfigs:/configs:rw"
#        "/workload/appdata/pdf/customFiles:/customFiles:rw"
#        "/workload/appdata/pdf/logs:/logs:rw"
#      ];
#      labels = {
#        "diun.enable" = "true";
#        "io.containers.autoupdate" = "registry";
#        "traefik.enable" = "true";
#        "traefik.http.services.pdf.loadbalancer.server.port" = "8080";
#      };
#      log-driver = "journald";
#      extraOptions = [
#        "--network-alias=pdf"
#        "--network=reverse-proxy"
#      ];
    };

    systemd.services."stirling-pdf" = {
      serviceConfig = {
        Restart = lib.mkOverride 500 "always";
      };
#      after = [
#        "zfs.target"
#        "podman-network-reverse-proxy.service"
#      ];
#      requires = [
#        "zfs.target"
#        "podman-network-reverse-proxy.service"
#      ];
      partOf = [
        "podman-compose-apps-root.target"
      ];
      wantedBy = [
        "podman-compose-apps-root.target"
      ];
    };
  };
}
