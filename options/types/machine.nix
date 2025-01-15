# Declares a machine type for reusability
#
# ### Features
# - _args is the composed/overridden set of user arguments for this machine
#
# - Easy assertions for debugging, just copy and paste
#  config = lib.mkMerge [
#    {
#      assertions = [
#        # General args
#        { assertion = (cfg.hostname == "nixos"); message = "machine.hostname: ${cfg.hostname}"; }
#        { assertion = (cfg.type.vm == true); message = "machine.type.vm: ${f.boolToStr cfg.type.vm}"; }
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
#
#        # Shares args
#        { assertion = (cfg.shares.enable == false); message = "machine.shares.enable: ${f.boolToStr cfg.shares.enable}"; }
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
#
#        # VM args
#        { assertion = (cfg.vm.cores == 1); message = "machine.vm.cores: ${toString cfg.vm.cores}"; }
#        { assertion = (cfg.vm.diskSize == 1024); message = "machine.vm.diskSize: ${toString cfg.vm.diskSize}"; }
#        { assertion = (cfg.vm.memorySize == 4096); message = "machine.vm.memorySize: ${toString cfg.vm.memorySize}"; }
#        { assertion = (cfg.vm.spice == true); message = "machine.vm.spice: ${f.boolToStr cfg.vm.spice}"; }
#        { assertion = (cfg.vm.spicePort == 5970); message = "machine.vm.spicePort: ${toString cfg.vm.spicePort}"; }
#        { assertion = (cfg.vm.graphics == true); message = "machine.vm.graphics: ${f.boolToStr cfg.vm.graphics}"; }
#      ];
#
#---------------------------------------------------------------------------------------------------
{ lib, _args, f, ... }: with lib.types;
let
  nic = import ./nic.nix { inherit lib; };
  drive = import ./drive.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  type = import ./machine_type.nix { inherit lib; };
  vm = import ./vm.nix { inherit lib; };
  share = import ./share.nix { inherit lib; };
in
{
  options = {

    enable = lib.mkOption {
      description = lib.mdDoc "Enable machine option";
      type = types.bool;
      default = false;
    };

    hostname = lib.mkOption {
      description = lib.mdDoc "Hostname";
      type = types.str;
      default = if (!builtins.hasAttr "hostname" _args || _args.hostname == null || _args.hostname == "")
        then "nixos" else _args.hostname;
    };

    type = lib.mkOption {
      description = lib.mdDoc "Machine type";
      type = types.submodule type;
      default = {
        vm = if (!builtins.hasAttr "vm_enable" _args || _args.vm_enable == null || !_args.vm_enable)
          then false else true;
        iso = if (!builtins.hasAttr "iso_enable" _args || _args.iso_enable == null || !_args.iso_enable)
          then false else true;
      };
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

    drive0 = lib.mkOption {
      description = lib.mdDoc "Drive options";
      type = types.submodule drive;
      default = {
        uuid = if (!builtins.hasAttr "drive0_uuid" _args || _args.drive0_uuid == null)
          then "" else _args.drive0_uuid;
      };
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

    nix_base = lib.mkOption {
      description = lib.mdDoc "NixOS base installed version";
      type = types.str;
      default = if (!builtins.hasAttr "nix_base" _args || _args.nix_base == null || _args.nix_base == "")
        then "24.05" else _args.nix_base;
    };

    cache = lib.mkOption {
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
      default = {
        enable = if (!builtins.hasAttr "cache_enable" _args || _args.cache_enable == null || _args.cache_enable == false)
          then false else true;
        ip = if (!builtins.hasAttr "cache_ip" _args || _args.cache_ip == null)
          then "" else _args.cache_ip;
      };
    };

    shares = lib.mkOption {
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            description = lib.mdDoc "Enable NFS shares";
            type = types.bool;
          };
          entries = lib.mkOption {
            description = lib.mdDoc "NFS shares to configure";
            type = types.listOf share;
          };
        };
      };
      default = {
        enable = if (!builtins.hasAttr "shares_enable" _args || _args.shares_enable == null || _args.shares_enable == false)
          then false else true;

        # TODO: need to set defalts from yaml
        entries = [ ];
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

    macvtap = lib.mkOption {
      type = types.submodule {
        options = {
          host = lib.mkOption {
            description = lib.mdDoc "NIC of the Macvtap host";
            type = types.str;
            default = "";
            example = "wlp3s0";
          };
        };
      };
      default = {
        host = if (!builtins.hasAttr "macvtap_host" _args || _args.macvtap_host == null)
          then "" else _args.macvtap_host;
      };
    };

    drive1-uuid = lib.mkOption {
      description = lib.mdDoc "Hard drive 1 UUID";
      type = types.str;
      default = "";
    };

    vms = lib.mkOption {
      description = lib.mdDoc "Virtual Machine definitions to host on this machine";
      type = types.listOf vm;
      default = [ ];
    };

    # Only applicable to VMs
    # ----------------------------------------------------------------------------------------------
    vm = lib.mkOption {
      type = types.submodule {
        options = {
          cores = lib.mkOption {
            description = lib.mdDoc "VM cores";
            type = types.int;
          };
          diskSize = lib.mkOption {
            description = lib.mdDoc "VM disk size in MiB";
            type = types.int;
          };
          memorySize = lib.mkOption {
            description = lib.mdDoc "VM memory size in MiB";
            type = types.int;
          };
          spice = lib.mkOption {
            description = lib.mdDoc "Enable SPICE for vm";
            type = types.bool;
            default = true;
          };
          spicePort = lib.mkOption {
            description = lib.mdDoc "SPICE port for vm";
            type = types.int;
            default = 5970;
          };
          graphics = lib.mkOption {
            description = lib.mdDoc "Enable VM video display";
            type = types.bool;
          };
        };
      };
      default = {
        cores = if (!builtins.hasAttr "vm_cores" _args || _args.vm_cores == null)
          then 1 else _args.vm_cores;
        diskSize = if (!builtins.hasAttr "vm_disk_size" _args || _args.vm_disk_size == null)
          then 1 * 1024 else _args.vm_disk_size * 1024;
        memorySize = if (!builtins.hasAttr "vm_memory_size" _args || _args.vm_memory_size == null)
          then 4 * 1024 else _args.vm_memory_size * 1024;
        spice = if (!builtins.hasAttr "vm_spice" _args || _args.vm_spice == null)
          then true else _args.vm_spice;
        spicePort = if (!builtins.hasAttr "vm_spice_port" _args || _args.vm_spice_port == null)
          then 5970 else _args.vm_spice_port;
        graphics = if (!builtins.hasAttr "vm_graphics" _args || _args.vm_graphics == null)
          then true else _args.vm_graphics;
      };
    };
  };
}
