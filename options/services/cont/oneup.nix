# OneUp configuration
# - https://github.com/phR0ze/oneup
#
# ### Description
# Flutter application for tracking points
#
# ### Deployment Features
# - Get status with: `systemctl status podman-oneup`
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.oneup;
  defaults = f.getService args "oneup" 2002 2002;
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.cont.oneup = lib.mkOption {
      description = lib.mdDoc "OneUp service options";
      type = types.submodule { imports = [ (import ../../types/service.nix { inherit lib defaults; }) ]; };
      default = defaults;
    };
  };
 
  config = lib.mkIf cfg.enable {

    # Create persistent directories for application
    systemd.tmpfiles.rules = [
      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
      "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
    ];

    # Generate the "podman-${cfg.name}" service unit for the container
    virtualisation.oci-containers.containers."${cfg.name}" = {
      image = "ghcr.io/phr0ze/${cfg.name}:${cfg.tag}";
      autoStart = true;
      hostname = "${cfg.name}";
      ports = [ "${(f.toIP cfg.nic.ip).address}:${toString cfg.port}:80" ];
      volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
      extraOptions = [
        "--network=${cfg.name}"
      ];
    };
  };
}
