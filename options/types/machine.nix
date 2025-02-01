# Declares a machine type for reusability
#
# ### Features
# - _args is the composed/overridden set of user arguments for this machine
#
#---------------------------------------------------------------------------------------------------
{ lib, _args, f, ... }: with lib.types;
let
  nic = import ./nic.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
in
{
  options = {
    enable = lib.mkOption {
      description = lib.mdDoc ''
        Enable machine option simply allows for at least one option to be set otherwise the defaults 
        don't seem to take effect.
      '';
      type = types.bool;
      default = false;
    };

    type = lib.mkOption {
      description = lib.mdDoc ''
        Machine types are descriptive capabilities of a machine. These types are not mutually 
        exclusive. For instance a machine might be both an ISO and also a development machine. 
      '';
      type = types.submodule {
        options = {
          iso = lib.mkOption {
            description = lib.mdDoc "Machine is intended to be used as an ISO image";
            type = types.bool;
            default = false;
          };
          develop = lib.mkOption {
            description = lib.mdDoc "Machine is intended to be used as a Development system";
            type = types.bool;
            default = false;
          };
          theater = lib.mkOption {
            description = lib.mdDoc "Machine is intended to be used as a Theater system";
            type = types.bool;
            default = false;
          };
        };
      };
      default = {
        iso = if (!builtins.hasAttr "iso_mode" _args || _args.iso_mode == null || !_args.iso_mode)
          then false else true;
      };
    };

    hostname = lib.mkOption {
      description = lib.mdDoc "Hostname";
      type = types.str;
      default = if (!builtins.hasAttr "hostname" _args || _args.hostname == null || _args.hostname == "")
        then "nixos" else _args.hostname;
    };

    profile = lib.mkOption {
      description = lib.mdDoc "Flake profile used during installation";
      type = types.str;
      default = if (!builtins.hasAttr "profile" _args || _args.profile == null || _args.profile == "")
        then "xfce/desktop" else _args.profile;
    };

    efi = lib.mkOption {
      description = lib.mdDoc "Enable EFI";
      type = types.bool;
      default = if (!builtins.hasAttr "efi" _args || _args.efi == null || _args.efi == false)
        then false else true;
    };

    mbr = lib.mkOption {
      description = lib.mdDoc "BIOS mbr is enabled when not 'nodev'";
      type = types.str;
      default = if (!builtins.hasAttr "mbr" _args || _args.mbr == null || _args.mbr == "")
        then "nodev" else _args.mbr;
    };

    drives = lib.mkOption {
      description = lib.mdDoc "Drive options";
      type = types.listOf (types.submodule {
        options = {
          uuid = lib.mkOption {
            description = lib.mdDoc "Drive identifier";
            type = types.str;
            default = "";
          };
        };
      });
      default = if (!builtins.hasAttr "drives" _args || _args.drives == null)
        then [ ] else _args.drives;
    };

    arch = lib.mkOption {
      description = lib.mdDoc "System architecture";
      type = types.str;
      default = if (!builtins.hasAttr "arch" _args || _args.arch == null || _args.arch == "")
        then "x86_64-linux" else _args.arch;
    };

    locale = lib.mkOption {
      description = lib.mdDoc "System locale";
      type = types.str;
      default = if (!builtins.hasAttr "locale" _args || _args.locale == null || _args.locale == "")
        then "en_US.UTF-8" else _args.locale;
    };

    timezone = lib.mkOption {
      description = lib.mdDoc "System timezone";
      type = types.str;
      default = if (!builtins.hasAttr "timezone" _args || _args.timezone == null || _args.timezone == "")
        then "America/Boise" else _args.timezone;
    };

    autologin = lib.mkOption {
      description = lib.mdDoc "Enable autologin";
      type = types.bool;
      default = if (!builtins.hasAttr "autologin" _args || _args.autologin == null || _args.autologin == false)
        then false else true;
    };

    bluetooth = lib.mkOption {
      description = lib.mdDoc "Enable bluetooth";
      type = types.bool;
      default = if (!builtins.hasAttr "bluetooth" _args || _args.bluetooth == null || _args.bluetooth == false)
        then false else true;
    };

    resolution = lib.mkOption {
      description = lib.mdDoc "Display resolution";
      type = types.attrs;
      default = {
        x = if (!builtins.hasAttr "resolution_x" _args || _args.resolution_x == null || _args.resolution_x == 0)
          then 0 else _args.resolution_x;
        y = if (!builtins.hasAttr "resolution_y" _args || _args.resolution_y == null || _args.resolution_y == 0)
          then 0 else _args.resolution_y;
      };
    };

    nix = lib.mkOption {
      type = types.submodule {
        options = {
          base = lib.mkOption {
            description = lib.mdDoc "NixOS base installed version";
            type = types.str;
          };
          cache = lib.mkOption {
            description = lib.mdDoc "Nix Binary cache configuration";
            type = types.submodule {
              options = {
                enable = lib.mkOption {
                  description = lib.mdDoc "Enable using a custom Nix binary cache";
                  type = types.bool;
                };
                ip = lib.mkOption {
                  description = lib.mdDoc "IP address of the custom Nix binary cache";
                  type = types.str;
                };
              };
            };
          };
        };
      };
      default = {
        base = if (!builtins.hasAttr "nix_base" _args || _args.nix_base == null || _args.nix_base == "")
          then "24.05" else _args.nix_base;
        cache = {
          enable = if (!builtins.hasAttr "nix_cache_enable" _args || _args.nix_cache_enable == null)
            then false else _args.nix_cache_enable;
          ip = if (!builtins.hasAttr "nix_cache_ip" _args || _args.nix_cache_ip == null)
            then "" else _args.nix_cache_ip;
        };
      };
    };

    nfs = lib.mkOption {
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            description = lib.mdDoc "Enable NFS shares";
            type = types.bool;
          };
          entries = lib.mkOption {
            description = lib.mdDoc "Share entries to configure";
            type = types.listOf (types.submodule {
              options = {
                mountPoint = lib.mkOption {
                  description = lib.mdDoc "Share mount point";
                  type = types.str;
                  example = "/mnt/Media";
                };
                remotePath = lib.mkOption {
                  description = lib.mdDoc "Remote path to use for the share";
                  type = types.str;
                  example = "192.168.1.2:/srv/nfs/Media";
                };
                fsType = lib.mkOption {
                  description = lib.mdDoc "Share file system type";
                  type = types.str;
                  example = "nfs";
                };
                options = lib.mkOption {
                  description = lib.mdDoc "Share options";
                  type = types.listOf types.str;
                  example = [ "auto" "noacl" "noatime" "nodiratime" "rsize=8192" "wsize=8192" "timeo=15" "_netdev" ];
                };
              };
            });
          };
        };
      };
      default = {
        enable = if (!builtins.hasAttr "nfs_enable" _args || _args.nfs_enable == null)
          then false else _args.nfs_enable;
        entries = if (!builtins.hasAttr "nfs_entries" _args || _args.nfs_entries == null)
          then [ ] else _args.nfs_entries;
      };
    };

    smb = lib.mkOption {
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            description = lib.mdDoc "Enable SMB shares";
            type = types.bool;
          };
          user = lib.mkOption {
            description = lib.mdDoc "Defalt access user if not overriden";
            type = types.str;
          };
          pass = lib.mkOption {
            description = lib.mdDoc "Defalt access pass if not overriden";
            type = types.str;
          };
          domain = lib.mkOption {
            description = lib.mdDoc "Default domain or workgroup to use";
            type = types.str;
            example = "WORKGROUP";
          };
          entries = lib.mkOption {
            description = lib.mdDoc "Share entries to configure";
            type = types.listOf (types.submodule {
              options = {
                mountPoint = lib.mkOption {
                  description = lib.mdDoc "Share mount point";
                  type = types.str;
                  example = "/mnt/Media";
                };
                remotePath = lib.mkOption {
                  description = lib.mdDoc "Remote path to use for the share";
                  type = types.str;
                  example = "//<IP_OR_HOST>/path/to/share";
                };
                user = lib.mkOption {
                  description = lib.mdDoc "Access user";
                  type = types.str;
                };
                pass = lib.mkOption {
                  description = lib.mdDoc "Access password";
                  type = types.str;
                };
                domain = lib.mkOption {
                  description = lib.mdDoc "Set the domain or workgroup to use";
                  type = types.str;
                  example = "WORKGROUP";
                };
                writable = lib.mkOption {
                  description = lib.mdDoc "Enable writing to the share";
                  type = types.bool;
                };
                options = lib.mkOption {
                  description = lib.mdDoc "Share options";
                  type = types.listOf types.str;
                  example = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=60" 
                    "x-systemd.device-timeout=5s" "x-systemd.mount-timeout=5s" ];
                };
              };
            });
          };
        };
      };
      default = {
        enable = if (!builtins.hasAttr "smb_enable" _args || _args.smb_enable == null)
          then false else _args.smb_enable;
        user = if (!builtins.hasAttr "user_name" _args || _args.user_name == null || _args.user_name == "")
          then "admin" else _args.user_name;
        pass = if (!builtins.hasAttr "smb_pass" _args || _args.smb_pass == null || _args.smb_pass == "")
          then "admin" else _args.smb_pass;
        domain = if (!builtins.hasAttr "smb_domain" _args || _args.smb_domain == null || _args.smb_domain == "")
          then "WORKGROUP" else _args.smb_domain;
        entries = if (!builtins.hasAttr "smb_entries" _args || _args.smb_entries == null)
          then [ ] else (builtins.concatMap (x: [ {
            mountPoint = x.mountPoint;
            remotePath = x.remotePath;
            user = if (!builtins.hasAttr "user" x || x.user == null || x.user == "")
              then _args.user_name else x.user;
            pass = if (!builtins.hasAttr "pass" x || x.pass == null || x.pass == "")
              then _args.smb_pass else x.pass;
            domain = if (!builtins.hasAttr "domain" x || x.domain == null || x.domain == "")
              then _args.smb_domain else x.domain;
            writable = if (!builtins.hasAttr "writable" x || x.writable == null)
              then false else x.writable;
            options = if (!builtins.hasAttr "options" x || x.options == null)
              then [ ] else x.options;
          }]) _args.smb_entries);
      };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options";
      type = types.submodule user;
      default = {
        name = if (!builtins.hasAttr "user_name" _args || _args.user_name == null || _args.user_name == "")
          then "admin" else _args.user_name;
        pass = if (!builtins.hasAttr "user_pass" _args || _args.user_pass == null || _args.user_pass == "")
          then "admin" else _args.user_pass;
        fullname = if (!builtins.hasAttr "user_fullname" _args || _args.user_fullname == null)
          then "" else _args.user_fullname;
        email = if (!builtins.hasAttr "user_email" _args || _args.user_email == null)
          then "" else _args.user_email;
      };
    };

    git = lib.mkOption {
      type = types.submodule {
        options = {
          user = lib.mkOption {
            description = lib.mdDoc "Git user name";
            type = types.str;
          };
          email = lib.mkOption {
            description = lib.mdDoc "Git email address";
            type = types.str;
          };
          comment = lib.mkOption {
            description = lib.mdDoc "System build comment";
            type = types.str;
          };
        };
      };
      default = {
        user = if (!builtins.hasAttr "git_user" _args || _args.git_user == null)
          then "" else _args.git_user;
        email = if (!builtins.hasAttr "git_email" _args || _args.git_email == null)
          then "" else _args.git_email;
        comment = if (!builtins.hasAttr "git_comment" _args || _args.git_comment == null)
          then "" else _args.git_comment;
      };
    };

    nic0 = lib.mkOption {
      description = lib.mdDoc "Primary NIC options";
      type = types.submodule nic;
      default = {
        name = if (!builtins.hasAttr "nic0_name" _args || _args.nic0_name == null)
          then "" else _args.nic0_name;
        subnet = if (!builtins.hasAttr "nic0_subnet" _args || _args.nic0_subnet == null)
          then "" else _args.nic0_subnet;
        gateway = if (!builtins.hasAttr "nic0_gateway" _args || _args.nic0_gateway == null)
          then "" else _args.nic0_gateway;
        ip = {
          full = if (!builtins.hasAttr "nic0_ip" _args || _args.nic0_ip == null)
            then "" else _args.nic0_ip;
          attrs = if (!builtins.hasAttr "nic0_ip" _args || _args.nic0_ip == null || _args.nic0_ip == "")
            then { address = ""; prefixLength = 24; } else f.toIP _args.nic0_ip;
        };
        dns = {
          primary = if (!builtins.hasAttr "dns_primary" _args || _args.dns_primary == null)
            then "1.1.1.1" else _args.dns_primary;
          fallback = if (!builtins.hasAttr "dns_fallback" _args || _args.dns_fallback == null)
            then "8.8.8.8" else _args.dns_fallback;
        };
      };
    };

    nic1 = lib.mkOption {
      description = lib.mdDoc "Secondary NIC options";
      type = types.submodule nic;
      default = {
        name = if (!builtins.hasAttr "nic1_name" _args || _args.nic1_name == null)
          then "" else _args.nic1_name;
        subnet = if (!builtins.hasAttr "nic1_subnet" _args || _args.nic1_subnet == null)
          then "" else _args.nic1_subnet;
        gateway = if (!builtins.hasAttr "nic1_gateway" _args || _args.nic1_gateway == null)
          then "" else _args.nic1_gateway;
        ip = {
          full = if (!builtins.hasAttr "nic1_ip" _args || _args.nic1_ip == null)
            then "" else _args.nic1_ip;
          attrs = if (!builtins.hasAttr "nic1_ip" _args || _args.nic1_ip == null || _args.nic1_ip == "")
            then { address = ""; prefixLength = 24; } else f.toIP _args.nic1_ip;
        };
        dns = {
          primary = if (!builtins.hasAttr "dns_primary" _args || _args.dns_primary == null)
            then "1.1.1.1" else _args.dns_primary;
          fallback = if (!builtins.hasAttr "dns_fallback" _args || _args.dns_fallback == null)
            then "8.8.8.8" else _args.dns_fallback;
        };
      };
    };

    vm = lib.mkOption {
      description = lib.mdDoc "Virtual machine type for this machine";
      type = types.submodule {
        options = {
          micro = lib.mkEnableOption "Minimal headless system";
          local = lib.mkEnableOption "Full desktop system with local graphical display";
          spice = lib.mkEnableOption "Full desktop system with remote SPICE display";
        };
      };
      default = {};
    };
  };
}

# - Easy assertions for debugging, just copy and paste
#  config = lib.mkMerge [
#    {
#      assertions = [
#        # General args
#        { assertion = (cfg.hostname == "nixos"); message = "machine.hostname: ${cfg.hostname}"; }
#        { assertion = (cfg.type.iso == false); message = "machine.type.iso: ${f.boolToStr cfg.type.iso}"; }
#        { assertion = (cfg.profile == "xfce/desktop"); message = "machine.profile: ${cfg.profile}"; }
#        { assertion = (cfg.efi == false); message = "machine.efi: ${f.boolToStr cfg.efi}"; }
#        { assertion = (cfg.mbr == "/dev/sda"); message = "machine.mbr: ${cfg.mbr}"; }
#        { assertion = (cfg.arch == "x86_64-linux"); message = "machine.arch: ${cfg.arch}"; }
#        { assertion = (cfg.locale == "en_US.UTF-8"); message = "machin.locale: ${cfg.locale}"; }
#        { assertion = (cfg.timezone == "America/Boise"); message = "machine.timezone: ${cfg.timezone}"; }
#        { assertion = (cfg.bluetooth == false); message = "machine.bluetooth: ${f.boolToStr cfg.bluetooth}"; }
#        { assertion = (cfg.autologin == true); message = "machine.autologin: ${f.boolToStr cfg.autologin}"; }
#        { assertion = (cfg.resolution.x == 0); message = "machine.resolution.x: ${toString cfg.resolution.x}"; }
#        { assertion = (cfg.resolution.y == 0); message = "machine.resolution.y: ${toString cfg.resolution.y}"; }
#        { assertion = (cfg.nix_base == "24.05"); message = "machine.nix_base: ${cfg.nix_base}"; }
#        { assertion = (builtins.length cfg.drives == 3); message = "drives: ${toString (builtins.length cfg.drives)}"; }
#        { assertion = ((builtins.elemAt cfg.drives 0).uuid == ""); message = "drives: ${(builtins.elemAt cfg.drives 0).uuid}"; }
#
#        # User args
#        { assertion = (cfg.user.fullname == "admin"); message = "machine.user.fullname: ${cfg.user.fullname}"; }
#        { assertion = (cfg.user.email == "admin"); message = "machine.user.email: ${cfg.user.email}"; }
#        { assertion = (cfg.user.name == "admin"); message = "machine.user.name: ${cfg.user.name}"; }
#        { assertion = (cfg.user.pass == "admin"); message = "machine.user.pass: ${cfg.user.pass}"; }
#
#        # Git args
#        { assertion = (cfg.git.user == "admin"); message = "machine.git.user: ${cfg.git.user}"; }
#        { assertion = (cfg.git.email == "admin"); message = "machine.git.email: ${cfg.git.email}"; }
#        { assertion = (cfg.git.comment == ""); message = "machine.git.comment: ${cfg.git.comment}"; }
#
#        # Network args
#        { assertion = (cfg.nic0.name == ""); message = "machine.nic0.name: ${cfg.nic0.name}"; }
#        { assertion = (cfg.nic0.subnet == "192.168.1.0/24"); message = "machine.nic0.subnet: ${cfg.nic0.subnet}"; }
#        { assertion = (cfg.nic0.gateway == "192.168.1.1"); message = "machine.nic0.gateway: ${cfg.nic0.gateway}"; }
#        { assertion = (cfg.nic0.ip.full == ""); message = "machine.nic0.ip.full: ${cfg.nic0.ip.full}"; }
#        { assertion = (cfg.nic0.ip.attrs.address == ""); message = "machine.nic0.ip.attrs.address: ${cfg.nic0.ip.attrs.address}"; }
#        { assertion = (cfg.nic0.ip.attrs.prefixLength == 24); message = "machine.nic0.ip.attrs.prefixLength: ${toString cfg.nic0.ip.attrs.prefixLength}"; }
#        { assertion = (cfg.nic0.dns.primary == "1.1.1.1"); message = "machine.nic0.dns.primary: ${cfg.nic0.dns.primary}"; }
#        { assertion = (cfg.nic0.dns.fallback == "8.8.8.8"); message = "machine.nic0.dns.fallback: ${cfg.nic0.dns.fallback}"; }
#
#        { assertion = (cfg.nic1.name == ""); message = "machine.nic1.name: ${cfg.nic1.name}"; }
#        { assertion = (cfg.nic1.subnet == ""); message = "machine.nic1.subnet: ${cfg.nic1.subnet}"; }
#        { assertion = (cfg.nic1.gateway == ""); message = "machine.nic1.gateway: ${cfg.nic1.gateway}"; }
#        { assertion = (cfg.nic1.ip.full == ""); message = "machine.nic1.ip.full: ${cfg.nic1.ip.full}"; }
#        { assertion = (cfg.nic1.ip.attrs.address == ""); message = "machine.nic1.ip.attrs.address: ${cfg.nic1.ip.attrs.address}"; }
#        { assertion = (cfg.nic1.ip.attrs.prefixLength == 24); message = "machine.nic1.ip.attrs.prefixLength: ${toString cfg.nic1.ip.attrs.prefixLength}"; }
#        { assertion = (cfg.nic1.dns.primary == "1.1.1.1"); message = "machine.nic1.dns.primary: ${cfg.nic1.dns.primary}"; }
#        { assertion = (cfg.nic1.dns.fallback == "8.8.8.8"); message = "machine.nic1.dns.fallback: ${cfg.nic1.dns.fallback}"; }
#      ];
