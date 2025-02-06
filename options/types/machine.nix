# Declares a machine type for reusability
#
# ### Features
# - _args is the composed/overridden set of user arguments for this machine
#
#---------------------------------------------------------------------------------------------------
{ lib, _args, f, ... }: with lib.types;
let
  dns = import ./dns.nix { inherit lib; };
  nic = import ./nic.nix { inherit lib; };
  smb = import ./smb.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
in
{
  options = {
    type = lib.mkOption {
      description = lib.mdDoc ''
        Machine types are descriptive capabilities of a machine. These types are not mutually 
        exclusive. For instance a machine might be both an ISO and also a development machine. At 
        least one type must be specified though.
      '';
      type = types.submodule {
        options = {
          bootable = lib.mkEnableOption "Machine requires a bootloader to boot up";
          vm = lib.mkEnableOption "Machine is a virtual and does not need a bootloader";
          iso = lib.mkEnableOption "Machine is intended to be used as an ISO image";
          develop = lib.mkEnableOption "Machine is intended to be used as a Development system";
          theater = lib.mkEnableOption "Machine is intended to be used as a Theater system";
        };
      };
      default = {
        # Note: not defining the other defaults here as I don't expect to support them in _args
        iso = if (!_args ? "type" || _args.type ? "iso") then false else _args.type.iso;
      };
    };

    vm.type = lib.mkOption {
      description = lib.mdDoc "Virtual machine type for this machine";
      type = types.submodule {
        options = {
          micro = lib.mkEnableOption "Minimal headless system";
          local = lib.mkEnableOption "Full desktop system with local graphical display";
          spice = lib.mkEnableOption "Full desktop system with remote SPICE display";
        };
      };
    };

    hostname = lib.mkOption {
      description = lib.mdDoc "Hostname";
      type = types.str;
      default = if (!_args ? "hostname" || _args.hostname == "") then "nixos" else _args.hostname;
    };

    profile = lib.mkOption {
      description = lib.mdDoc "Flake profile used during installation";
      type = types.str;
      default = if (!_args ? "profile" || _args.profile == "") then "xfce/desktop" else _args.profile;
    };

    efi = lib.mkOption {
      description = lib.mdDoc "Enable EFI";
      type = types.bool;
      default = if (!_args ? "efi") then false else _args.efi;
    };

    mbr = lib.mkOption {
      description = lib.mdDoc "BIOS mbr is enabled when not 'nodev'";
      type = types.str;
      default = if (!_args ? "mbr" || _args.mbr == "") then "nodev" else _args.mbr;
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
      default = if (!_args ? "drives") then [ ] else _args.drives;
    };

    arch = lib.mkOption {
      description = lib.mdDoc "System architecture";
      type = types.str;
      default = if (!_args ? "arch" || _args.arch == "") then "x86_64-linux" else _args.arch;
    };

    locale = lib.mkOption {
      description = lib.mdDoc "System locale";
      type = types.str;
      default = if (!_args ? "locale" || _args.locale == "") then "en_US.UTF-8" else _args.locale;
    };

    timezone = lib.mkOption {
      description = lib.mdDoc "System timezone";
      type = types.str;
      default = if (!_args ? "timezone" || _args.timezone == "") then "America/Boise" else _args.timezone;
    };

    autologin = lib.mkOption {
      description = lib.mdDoc "Enable autologin";
      type = types.bool;
      default = if (!_args ? "autologin") then false else _args.autologin;
    };

    bluetooth = lib.mkOption {
      description = lib.mdDoc "Enable bluetooth";
      type = types.bool;
      default = if (!_args ? "bluetooth") then false else _args.bluetooth;
    };

    resolution = lib.mkOption {
      description = lib.mdDoc "Display resolution";
      type = types.attrs;
      default = {
        x = if (!_args ? "resolution" || !_args.resolution ? "x") then 0 else _args.resolution.x;
        y = if (!_args ? "resolution" || !_args.resolution ? "y") then 0 else _args.resolution.y;
      };
    };

    nix = lib.mkOption {
      type = types.submodule {
        options = {
          minVer = lib.mkOption {
            description = lib.mdDoc "Minimal support Nixpkgs version";
            type = types.str;
            default = if (!_args ? "nix" || !_args.nix ? "minVer" || _args.nix.minVer == "")
              then "25.05" else _args.nix.minVer;
          };
          cache = lib.mkOption {
            description = lib.mdDoc "Nix Binary cache configuration";
            type = types.submodule {
              options = {
                enable = lib.mkOption {
                  description = lib.mdDoc "Enable using a custom Nix binary cache";
                  type = types.bool;
                  default = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "enable")
                    then false else _args.nix.cache.enable;
                };
                ip = lib.mkOption {
                  description = lib.mdDoc "IP address of the custom Nix binary cache";
                  type = types.str;
                  default = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "ip")
                    then "" else _args.nix.cache.ip;
                };
              };
            };
            default = {
              enable = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "enable")
                then false else _args.nix.cache.enable;
              ip = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "ip")
                then "" else _args.nix.cache.ip;
            };
          };
        };
      };
      default = {
        minVer = if (!_args ? "nix" || !_args.nix ? "minVer" || _args.nix.minVer == "")
          then "25.05" else _args.nix.minVer;
        cache = {
          enable = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "enable")
            then false else _args.nix.cache.enable;
          ip = if (!_args ? "nix" || !_args.nix ? "cache" || !_args.nix.cache ? "ip")
            then "" else _args.nix.cache.ip;
        };
      };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options";
      type = types.submodule user;
      default = {
        name = if (!_args ? "user" || !_args.user ? "name" || _args.user.name == "")
          then "admin" else _args.user.name;
        pass = if (!_args ? "user" || !_args.user ? "pass" || _args.user.pass == "")
          then "admin" else _args.user.pass;
        fullname = if (!_args ? "user" || !_args.user ? "fullname") then "" else _args.user.fullname;
        email = if (!_args ? "user" || !_args.user ? "email") then "" else _args.user.email;
      };
    };

    git = lib.mkOption {
      type = types.submodule {
        options = {
          user = lib.mkOption {
            description = lib.mdDoc "Git user name";
            type = types.str;
            default = if (!_args ? "git" || !_args.git ? "user") then "" else _args.git.user;
          };
          email = lib.mkOption {
            description = lib.mdDoc "Git email address";
            type = types.str;
            default = if (!_args ? "git" || !_args.git ? "email") then "" else _args.git.email;
          };
          comment = lib.mkOption {
            description = lib.mdDoc "System build comment";
            type = types.str;
            default = if (!_args ? "git" || !_args.git ? "comment") then "" else _args.git.comment;
          };
        };
      };
      default = {
        user = if (!_args ? "git" || !_args.git ? "user") then "" else _args.git.user;
        email = if (!_args ? "git" || !_args.git ? "email") then "" else _args.git.email;
        comment = if (!_args ? "git" || !_args.git ? "comment") then "" else _args.git.comment;
      };
    };

    # Networking options for the machine
    # ----------------------------------------------------------------------------------------------
    net = lib.mkOption {
      description = lib.mdDoc "Networking options for the machine";
      type = types.submodule {
        options = {
          bridge = {
            enable = lib.mkEnableOption ''
              Convert the main interface into a bridge which then allows virtualized devices like 
              containers and VMs to join the LAN, be assigend LAN IP addresses and fully interact 
              with other devices on the LAN. All of the other primary network settings will be used 
              for the new bridge interface.
            '';
            name = lib.mkOption {
              type = types.str;
              description = lib.mdDoc "Name to use for the new bridge";
              default = "br0";
            };
          };
          macvlan = lib.mkOption {
            description = lib.mdDoc ''
              Create a macvlan interface for the host to use on the bridge, which allows the host to 
              communicate with virtualized devices connected to the bridge. Otherwise the virtualized 
              devices can fully participate on the LAN but they won't be able to interact directly 
              with the host nor will the host be able to interact directly with them.
            '';
            type = types.submodule {
              options = {
                name = lib.mkOption {
                  description = lib.mdDoc "Macvlan name to use";
                  type = types.str;
                  default = "host";
                };
                ip = lib.mkOption {
                  description = lib.mdDoc "Optional static ip to use else DHCP is used";
                  type = types.str;
                  example = "192.168.1.49";
                  default = "";
                };
              };
            };
            default = { name = "host"; ip = ""; };
          };
          gateway = lib.mkOption {
            description = lib.mdDoc "Default gateway for the system";
            type = types.str;
            default = if (!_args ? "net" || !_args.net ? "gateway") then "" else _args.net.gateway;
          };
          subnet = lib.mkOption {
            description = lib.mdDoc "Default subnet for the system";
            type = types.str;
            default = if (!_args ? "net" || !_args.net ? "subnet") then "" else _args.net.subnet;
          };
          dns = lib.mkOption {
            description = lib.mdDoc "Default DNS for the system";
            type = types.submodule dns;
            default = {
              primary = if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "primary")
                then "1.1.1.1" else _args.net.dns.primary;
              fallback = if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "fallback")
                then "8.8.8.8" else _args.net.dns.fallback;
            };
          };
        };
      };
      default = {
        bridge = { enable = false; };
        macvlan = { name = "host"; ip = "host"; };
        gateway = if (!_args ? "net" || !_args.net ? "gateway") then "" else _args.net.gateway;
        subnet = if (!_args ? "net" || !_args.net ? "subnet") then "" else _args.net.subnet;
        dns = {
          primary = if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "primary")
            then "1.1.1.1" else _args.net.dns.primary;
          fallback = if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "fallback")
            then "8.8.8.8" else _args.net.dns.fallback;
        };
      };
    };

    nics = lib.mkOption {
      description = lib.mdDoc "List of NIC options";
      type = types.listOf (types.submodule nic);
      default = if (!_args ? "nics") then [] else (builtins.concatMap (x: [{
        name = if (!x ? "name") then "" else x.name;
        id = if (!x ? "id") then "" else x.id;
        link = if (!x ? "link") then "" else x.link;

        # Fallback on the global network settings in _args.net
        subnet = if (!x ? "subnet") then (if (!_args ? "net" || !_args.net ? "subnet")
          then "" else _args.net.subnet) else x.subnet;
        gateway = if (!x ? "gateway") then (if (!_args ? "net" || !_args.net ? "gateway")
          then "" else _args.net.gateway) else x.gateway;
        ip = {
          full = if (!x ? "ip") then "" else x.ip;
          attrs = if (!x ? "ip") then { address = ""; prefixLength = 24; } else f.toIP x.ip;
        };
        dns = {
          # Fallback on the global network settings in _args.net
          primary = if (!x ? "dns" || !x.dns ? "primary")
            then (if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "primary")
              then "1.1.1.1" else _args.net.dns.primary) else x.dns.primary;
          fallback = if (!x ? "dns" || !x.dns ? "fallback")
            then (if (!_args ? "net" || !_args.net ? "dns" || !_args.net.dns ? "fallback")
              then "8.8.8.8" else _args.net.dns.fallback) else x.dns.fallback;
        };
      }]) _args.nics);
    };

    smb = lib.mkOption {
      type = types.submodule smb;
      default = {
        enable = if (!_args ? "smb" || !_args.smb ? "enable") then false else _args.smb.enable;
        user = if (!_args ? "smb" || !_args.smb ? "user") then "" else _args.smb.user;
        pass = if (!_args ? "smb" || !_args.smb ? "pass") then "" else _args.smb.pass;
        domain = if (!_args ? "smb" || !_args.smb ? "domain") then "" else _args.smb.domain;
        entries = if (!_args ? "smb" || !_args.smb ? "entries") then [] else (builtins.concatMap (x: [{
          mountPoint = if (!x ? "mountPoint") then "" else x.mountPoint;
          remotePath = if (!x ? "remotePath") then "" else x.remotePath;
          user = if (!x ? "user" || x.user == "") then (if (!_args ? "smb" || !_args.smb ? "user")
            then "" else _args.smb.user) else x.user;
          pass = if (!x ? "pass" || x.pass == "") then (if (!_args ? "smb" || !_args.smb ? "pass")
            then "" else _args.smb.pass) else x.pass;
          domain = if (!x ? "domain" || x.domain == "") then (if (!_args ? "smb" || !_args.smb ? "domain")
            then "" else _args.smb.domain) else x.domain;
          writable = if (!x ? "writable") then false else x.writable;
          options = if (!x ? "options") then [] else x.options;
        }]) _args.smb.entries);
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
        enable = if (!_args ? "nfs" || !_args.nfs ? "enable") then false else _args.nfs.enable;
        entries = if (!_args ? "nfs" || !_args.nfs ? "entries") then [] else _args.nfs.entries;
      };
    };


  };
}
