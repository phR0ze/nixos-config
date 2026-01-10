{ config, lib, cfg, ... }:
let
  machine = config.machine;
in
{
  config = lib.mkIf cfg.enable {

    # Common assertions among services
    assertions = [
      # Debug assertion
      #{ assertion = (cfg ? "debug"); message = "echo '${builtins.toJSON cfg}' | jq"; }

      { assertion = (cfg ? "name" && cfg.name != "");
        message = "Requires 'service.oci.${cfg.name}.name' => '${builtins.toJSON cfg.name}' be set to the service name"; }
      { assertion = (machine.net.nic0.name != "");
        message = "Requires 'machine.net.nic0.name' => '${builtins.toJSON machine.net.nic0.name}' be set to a NIC name"; }
      { assertion = (machine.net.nic0.ip != "");
        message = "Requires 'machine.net.nic0.ip' => '${builtins.toJSON machine.net.nic0.ip}' be set to a static IP address"; }
      { assertion = (cfg ? "port" && cfg.port > 0);
        message = "Requires 'service.oci.${cfg.name}.port' => '${builtins.toJSON cfg.port}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "name" && cfg.user.name != null && cfg.user.name != "");
        message = "Requires 'service.oci.${cfg.name}.user.name' => '${builtins.toJSON cfg.user.name}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "group" && cfg.user.group != null && cfg.user.group != "");
        message = "Requires 'service.oci.${cfg.name}.user.group' => '${builtins.toJSON cfg.user.group}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "uid" && cfg.user.uid != null && cfg.user.uid > 0);
        message = "Requires 'service.oci.${cfg.name}.user.uid' => '${builtins.toJSON cfg.user.uid}' be set"; }
      { assertion = (cfg ? "user" && cfg.user ? "gid" && cfg.user.gid != null && cfg.user.gid > 0);
        message = "Requires 'service.oci.${cfg.name}.user.gid' => '${builtins.toJSON cfg.user.gid}' be set"; }
    ];
  };
}
