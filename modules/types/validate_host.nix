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

    # Ensure the existance of input args
    # ----------------------------------------------------------------------------------------------
    # In the ISO case args.host.id is not set
    #{ assertion = (args.host.id != null && args.host.id != ""); message = "assert args.host.id: ${args.host.id}"; }
    { assertion = (args.host.hostname != null && args.host.hostname != ""); message = "assert args.host.hostname: ${args.host.hostname}"; }
    { assertion = (args.host.target != null); message = "assert args.host.target: ${args.host.target}"; }
    { assertion = (args.host.efi != null); message = "assert args.host.efi: ${f.boolToStr args.host.efi}"; }
    { assertion = (args.host.mbr != null); message = "assert args.host.mbr: ${args.host.mbr}"; }
    { assertion = (args.host.arch == "x86_64-linux"); message = "assert args.host.arch: ${args.host.arch}"; }
    { assertion = (args.host.locale == "en_US.UTF-8"); message = "assert args.host.locale: ${args.host.locale}"; }
    { assertion = (args.host.timezone == "America/Boise"); message = "assert args.host.timezone: ${args.host.timezone}"; }
    { assertion = (args.host.bluetooth != null); message = "assert args.host.bluetooth: ${f.boolToStr args.host.bluetooth}"; }
    { assertion = (args.host.autologin != null); message = "assert args.host.autologin: ${f.boolToStr args.host.autologin}"; }
    { assertion = (args.host.resolution.x != null); message = "assert args.host.resolution.x: ${toString args.host.resolution.x}"; }
    { assertion = (args.host.resolution.y != null); message = "assert args.host.resolution.y: ${toString args.host.resolution.y}"; }
    { assertion = (args.host.nix.minVer != ""); message = "assert args.host.nix.minVer: ${args.host.nix.minVer}"; }

    { assertion = (args.user.name != null && args.user.name != ""); message = "assert args.user.name exists"; }
    { assertion = (args.user.pass != null); message = "assert args.user.pass: ${args.user.pass}"; }
    { assertion = (args.user.fullname != null); message = "assert args.user.fullname: ${args.user.fullname}"; }
    { assertion = (args.user.email != null); message = "assert args.user.email: ${args.user.email}"; }

    { assertion = (args.host.git.user != null); message = "assert args.host.git.user: ${args.host.git.user}"; }
    { assertion = (args.host.git.email != null); message = "assert args.host.git.email: ${args.host.git.email}"; }
    { assertion = (args.host.git.comment != null); message = "assert args.host.git.comment: ${args.host.git.comment}"; }

    { assertion = (args.host.nix.cache.enable != null); message = "assert args.host.nix.cache.enable: ${args.host.nix.cache.enable}"; }

    # Ensure the existance of final merged args
    # ----------------------------------------------------------------------------------------------
    { assertion = (cfg.hostname != null); message = "assert host.hostname: ${cfg.hostname}"; }
    { assertion = (cfg.target != null); message = "assert host.target: ${cfg.target}"; }
    { assertion = (cfg.efi != null); message = "assert host.efi: ${f.boolToStr cfg.efi}"; }
    { assertion = (cfg.mbr != null); message = "assert host.mbr: ${cfg.mbr}"; }
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
    { assertion = (cfg.smb.entries != null); message = "assert host.smb.entries: ${toString (builtins.length cfg.smb.entries)}"; }
    { assertion = (cfg.nfs.entries != null); message = "assert host.nfs.entries: ${toString (builtins.length cfg.nfs.entries)}"; }
  ];
}
