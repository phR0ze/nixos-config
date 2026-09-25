{ config, args, f, ... }:
let
  cfg = config.host;
in
{
  assertions = [
    # Debug arg values
    #{ assertion = (args.user.name != null && args.user.name == "bob");
    #  message = "echo '${builtins.toJSON args}' | jq"; }

    # Debug final values
    # { assertion = (args.user.name != null && args.user.name == "bob");
    #   message = "echo '${builtins.toJSON cfg}' | jq"; }

    # Ensure the existance of final merged args
    # ----------------------------------------------------------------------------------------------
    { assertion = (cfg.target != null); message = "assert host.target: ${cfg.target}"; }
    { assertion = (cfg.arch == "x86_64-linux"); message = "assert host.arch: ${cfg.arch}"; }
    { assertion = (cfg.locale == "en_US.UTF-8"); message = "assert host.locale: ${cfg.locale}"; }
    { assertion = (cfg.timezone == "America/Boise"); message = "assert host.timezone: ${cfg.timezone}"; }
    { assertion = (cfg.bluetooth != null); message = "assert host.bluetooth: ${f.boolToStr cfg.bluetooth}"; }
    { assertion = (cfg.autologin != null); message = "assert host.autologin: ${f.boolToStr cfg.autologin}"; }
    { assertion = (cfg.resolution.x != null); message = "assert host.resolution.x: ${toString cfg.resolution.x}"; }
    { assertion = (cfg.resolution.y != null); message = "assert host.resolution.y: ${toString cfg.resolution.y}"; }
    { assertion = (cfg.type.iso != null); message = "assert host.type.iso: ${f.boolToStr cfg.type.iso}"; }
    { assertion = (cfg.type.vm != null); message = "assert host.type.vm: ${f.boolToStr cfg.type.vm}"; }
    { assertion = (cfg.nix.minVer != ""); message = "assert host.nix.minVer: ${cfg.nix.minVer}"; }

    { assertion = (cfg.user.fullname != null); message = "assert host.user.fullname: ${cfg.user.fullname}"; }
    { assertion = (cfg.user.email != null); message = "assert host.user.email: ${cfg.user.email}"; }
    { assertion = (cfg.user.name != null); message = "assert host.user.name: ${cfg.user.name}"; }
    { assertion = (cfg.user.pass != null); message = "assert host.user.pass: ${cfg.user.pass}"; }

    { assertion = (cfg.git.user != null); message = "assert host.git.user: ${cfg.git.user}"; }
    { assertion = (cfg.git.email != null); message = "assert host.git.email: ${cfg.git.email}"; }
    { assertion = (cfg.git.comment != null); message = "assert host.git.comment: ${cfg.git.comment}"; }

    { assertion = (cfg.net.bridge.enable != null); message = "assert host.net.bridge.enable: ${cfg.net.bridge.enable}"; }
    { assertion = (cfg.net.bridge.name != null); message = "assert host.net.bridge.name: ${cfg.net.bridge.name}"; }
    { assertion = (cfg.net.macvlan.name != null); message = "assert host.net.macvlan.name: ${cfg.net.macvlan.name}"; }
    { assertion = (cfg.net.macvlan.ip != null); message = "assert host.net.macvlan.ip: ${cfg.net.macvlan.ip}"; }
    { assertion = (cfg.net.macvlan.mac != null); message = "assert host.net.macvlan.mac: ${cfg.net.macvlan.mac}"; }

    { assertion = (cfg.nix.cache.enable != null); message = "assert host.nix.cache.enable: ${cfg.nix.cache.enable}"; }
    { assertion = (cfg.nix.cache.ip != null); message = "assert host.nix.cache.ip: ${cfg.nix.cache.ip}"; }

    { assertion = (cfg.drives != null); message = "assert host.drives: ${toString (builtins.length cfg.drives)}"; }
  ];
}
