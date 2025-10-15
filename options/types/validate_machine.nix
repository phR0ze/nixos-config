{ config, lib, args, f, ... }:
let
  cfg = config.machine;
in
{
  assertions = [
    # Debug arg values
    #{ assertion = (args.user.name != null && args.user.name == "bob");
    #  message = "echo '${builtins.toJSON args}' | jq"; }

    # Debug final values
    #{ assertion = (args.user.name != null && args.user.name == "bob");
    #  message = "echo '${builtins.toJSON cfg}' | jq"; }

    # Ensure the existance of input args
    # ----------------------------------------------------------------------------------------------
    # In the ISO case args.id is not set
    #{ assertion = (args.id != null && args.id != ""); message = "assert args.id: ${args.id}"; }
    { assertion = (args.hostname != null && args.hostname != ""); message = "assert args.hostname: ${args.hostname}"; }
    { assertion = (args.target != null); message = "assert args.target: ${args.target}"; }
    { assertion = (args.efi != null); message = "assert args.efi: ${f.boolToStr args.efi}"; }
    { assertion = (args.mbr != null); message = "assert args.mbr: ${args.mbr}"; }
    { assertion = (args.arch == "x86_64-linux"); message = "assert args.arch: ${args.arch}"; }
    { assertion = (args.locale == "en_US.UTF-8"); message = "assert args.locale: ${args.locale}"; }
    { assertion = (args.timezone == "America/Boise"); message = "assert args.timezone: ${args.timezone}"; }
    { assertion = (args.bluetooth != null); message = "assert args.bluetooth: ${f.boolToStr args.bluetooth}"; }
    { assertion = (args.autologin != null); message = "assert args.autologin: ${f.boolToStr args.autologin}"; }
    { assertion = (args.resolution.x != null); message = "assert args.resolution.x: ${toString args.resolution.x}"; }
    { assertion = (args.resolution.y != null); message = "assert args.resolution.y: ${toString args.resolution.y}"; }
    { assertion = (args.nix.minVer == "25.05"); message = "assert machine.nix.minVer: ${args.nix.minVer}"; }

    { assertion = (args.user.name != null && args.user.name != ""); message = "assert args.user.name exists"; }
    { assertion = (args.user.pass != null); message = "assert args.user.pass: ${args.user.pass}"; }
    { assertion = (args.user.fullname != null); message = "assert args.user.fullname: ${args.user.fullname}"; }
    { assertion = (args.user.email != null); message = "assert args.user.email: ${args.user.email}"; }

    { assertion = (args.git.user != null); message = "assert args.git.user: ${args.git.user}"; }
    { assertion = (args.git.email != null); message = "assert args.git.email: ${args.git.email}"; }
    { assertion = (args.git.comment != null); message = "assert args.git.comment: ${args.git.comment}"; }

    { assertion = (args.nix.cache.enable != null); message = "assert args.nix.cache.enable: ${args.nix.cache.enable}"; }
    { assertion = (args.nix.cache.ip != null); message = "assert args.nix.cache.ip: ${args.nix.cache.ip}"; }

    # Ensure the existance of final merged args
    # ----------------------------------------------------------------------------------------------
    { assertion = (cfg.hostname != null); message = "assert machine.hostname: ${cfg.hostname}"; }
    { assertion = (cfg.target != null); message = "assert machine.target: ${cfg.target}"; }
    { assertion = (cfg.efi != null); message = "assert machine.efi: ${f.boolToStr cfg.efi}"; }
    { assertion = (cfg.mbr != null); message = "assert machine.mbr: ${cfg.mbr}"; }
    { assertion = (cfg.arch == "x86_64-linux"); message = "assert machine.arch: ${cfg.arch}"; }
    { assertion = (cfg.locale == "en_US.UTF-8"); message = "assert machine.locale: ${cfg.locale}"; }
    { assertion = (cfg.timezone == "America/Boise"); message = "assert machine.timezone: ${cfg.timezone}"; }
    { assertion = (cfg.bluetooth != null); message = "assert machine.bluetooth: ${f.boolToStr cfg.bluetooth}"; }
    { assertion = (cfg.autologin != null); message = "assert machine.autologin: ${f.boolToStr cfg.autologin}"; }
    { assertion = (cfg.resolution.x != null); message = "assert machine.resolution.x: ${toString cfg.resolution.x}"; }
    { assertion = (cfg.resolution.y != null); message = "assert machine.resolution.y: ${toString cfg.resolution.y}"; }
    { assertion = (cfg.type.iso != null); message = "assert machine.type.iso: ${f.boolToStr cfg.type.iso}"; }
    { assertion = (cfg.type.vm != null); message = "assert machine.type.vm: ${f.boolToStr cfg.type.vm}"; }
    { assertion = (cfg.nix.minVer == "25.05"); message = "assert machine.nix.minVer: ${cfg.nix.minVer}"; }

    { assertion = (cfg.user.fullname != null); message = "assert machine.user.fullname: ${cfg.user.fullname}"; }
    { assertion = (cfg.user.email != null); message = "assert machine.user.email: ${cfg.user.email}"; }
    { assertion = (cfg.user.name != null); message = "assert machine.user.name: ${cfg.user.name}"; }
    { assertion = (cfg.user.pass != null); message = "assert machine.user.pass: ${cfg.user.pass}"; }

    { assertion = (cfg.git.user != null); message = "assert machine.git.user: ${cfg.git.user}"; }
    { assertion = (cfg.git.email != null); message = "assert machine.git.email: ${cfg.git.email}"; }
    { assertion = (cfg.git.comment != null); message = "assert machine.git.comment: ${cfg.git.comment}"; }

    { assertion = (cfg.net.bridge.enable != null); message = "assert machine.net.bridge.enable: ${cfg.net.bridge.enable}"; }
    { assertion = (cfg.net.bridge.name != null); message = "assert machine.net.bridge.name: ${cfg.net.bridge.name}"; }
    { assertion = (cfg.net.macvlan.name != null); message = "assert machine.net.macvlan.name: ${cfg.net.macvlan.name}"; }
    { assertion = (cfg.net.macvlan.ip != null); message = "assert machine.net.macvlan.ip: ${cfg.net.macvlan.ip}"; }

    { assertion = (cfg.nix.cache.enable != null); message = "assert machine.nix.cache.enable: ${cfg.nix.cache.enable}"; }
    { assertion = (cfg.nix.cache.ip != null); message = "assert machine.nix.cache.ip: ${cfg.nix.cache.ip}"; }

    { assertion = (cfg.drives != null); message = "assert machine.drives: ${toString (builtins.length cfg.drives)}"; }
    { assertion = (cfg.smb.entries != null); message = "assert machine.smb.entries: ${toString (builtins.length cfg.smb.entries)}"; }
    { assertion = (cfg.nfs.entries != null); message = "assert machine.nfs.entries: ${toString (builtins.length cfg.nfs.entries)}"; }
  ];
}
