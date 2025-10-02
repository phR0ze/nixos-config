# Immich
#
# ### Description
# Immich is a Self-hosted photo and video mangement solution to easily back up, organize and manage 
# your photos on your own server. Immich helps you browse, seach and organize your photos and videos 
# with ease, without sacrificing your privacy.
#
# ### References
# 
# --------------------------------------------------------------------------------------------------
{ config, lib, args, pkgs, f, ... }: with lib.types;
let
  machine = config.machine;
  cfg = config.services.cont.immich;
  defaults = (f.getService args "immich" 2003 2003);
in
{
  imports = [ (import ../../types/service_base.nix { inherit config lib pkgs f cfg; }) ];

  options = {
    services.cont.immich = lib.mkOption {
      description = lib.mdDoc "Immich service options";
      type = types.submodule { imports = [ (import ../../types/service.nix { inherit lib defaults; }) ]; };
      default = defaults;
    };
  };

  config = lib.mkIf cfg.enable {

    # Add access to hardware acceleration for transcoding
    # - https://wiki.nixos.org/wiki/Immich
    users.users.${cfg.user.name}.extraGroups = [ "video" "render" ];

#    # Create persistent directories for application
#    systemd.tmpfiles.rules = [
#      "d /var/lib/${cfg.name} 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
#      "d /var/lib/${cfg.name}/data 0750 ${toString cfg.user.uid} ${toString cfg.user.gid} -"
#    ];
#
#    # Generate the "podman-${cfg.name}" service unit for the container
#    virtualisation.oci-containers.containers."${cfg.name}" = {
#      image = "ghcr.io/phr0ze/${cfg.name}:${cfg.tag}";
#      autoStart = true;
#      hostname = "${cfg.name}";
#      ports = [ "${(f.toIP config.net.primary.ip).address}:${toString cfg.port}:80" ];
#      volumes = [ "/var/lib/${cfg.name}/data:/app/data:rw" ];
#      extraOptions = [
#        "--network=${cfg.name}"
#      ];
#    };
  };
}
