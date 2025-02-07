# Declares a machine type for reusability
#
# ### Features
# - args is the composed/overridden set of user arguments for this machine
#
#---------------------------------------------------------------------------------------------------
{ lib, args, f, ... }: with lib.types;
let
  nic = import ./nic.nix { inherit lib; };
  smb = import ./smb.nix { inherit lib; };
  service = import ./service.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };

  # Shortcuts for reused items
  user_name = if (!args ? "user" || !args.user ? "name") then "admin" else args.user.name;
  user_pass = if (!args ? "user" || !args.user ? "pass" || args.user.pass == "") then "admin" else args.user.pass;
  uid = config.users.users.${user_name}.uid;
  gid = config.users.groups."users".gid;
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
        # Note: not defining the other defaults here as I don't expect to support them in args
        iso = if (!args ? "type" || args.type ? "iso") then false else args.type.iso;
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
      default = if (!args ? "hostname" || args.hostname == "") then "nixos" else args.hostname;
    };

    profile = lib.mkOption {
      description = lib.mdDoc "Flake profile used during installation";
      type = types.str;
      default = if (!args ? "profile" || args.profile == "") then "xfce/desktop" else args.profile;
    };

    efi = lib.mkOption {
      description = lib.mdDoc "Enable EFI";
      type = types.bool;
      default = if (!args ? "efi") then false else args.efi;
    };

    mbr = lib.mkOption {
      description = lib.mdDoc "BIOS mbr is enabled when not 'nodev'";
      type = types.str;
      default = if (!args ? "mbr" || args.mbr == "") then "nodev" else args.mbr;
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
      default = if (!args ? "drives") then [ ] else args.drives;
    };

    arch = lib.mkOption {
      description = lib.mdDoc "System architecture";
      type = types.str;
      default = if (!args ? "arch" || args.arch == "") then "x86_64-linux" else args.arch;
    };

    locale = lib.mkOption {
      description = lib.mdDoc "System locale";
      type = types.str;
      default = if (!args ? "locale" || args.locale == "") then "en_US.UTF-8" else args.locale;
    };

    timezone = lib.mkOption {
      description = lib.mdDoc "System timezone";
      type = types.str;
      default = if (!args ? "timezone" || args.timezone == "") then "America/Boise" else args.timezone;
    };

    autologin = lib.mkOption {
      description = lib.mdDoc "Enable autologin";
      type = types.bool;
      default = if (!args ? "autologin") then false else args.autologin;
    };

    bluetooth = lib.mkOption {
      description = lib.mdDoc "Enable bluetooth";
      type = types.bool;
      default = if (!args ? "bluetooth") then false else args.bluetooth;
    };

    resolution = lib.mkOption {
      description = lib.mdDoc "Display resolution";
      type = types.attrs;
      default = {
        x = if (!args ? "resolution" || !args.resolution ? "x") then 0 else args.resolution.x;
        y = if (!args ? "resolution" || !args.resolution ? "y") then 0 else args.resolution.y;
      };
    };

    nix = lib.mkOption {
      type = types.submodule {
        options = {
          minVer = lib.mkOption {
            description = lib.mdDoc "Minimal support Nixpkgs version";
            type = types.str;
            default = if (!args ? "nix" || !args.nix ? "minVer" || args.nix.minVer == "")
              then "25.05" else args.nix.minVer;
          };
          cache = lib.mkOption {
            description = lib.mdDoc "Nix Binary cache configuration";
            type = types.submodule {
              options = {
                enable = lib.mkOption {
                  description = lib.mdDoc "Enable using a custom Nix binary cache";
                  type = types.bool;
                  default = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "enable")
                    then false else args.nix.cache.enable;
                };
                ip = lib.mkOption {
                  description = lib.mdDoc "IP address of the custom Nix binary cache";
                  type = types.str;
                  default = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "ip")
                    then "" else args.nix.cache.ip;
                };
              };
            };
            default = {
              enable = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "enable")
                then false else args.nix.cache.enable;
              ip = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "ip")
                then "" else args.nix.cache.ip;
            };
          };
        };
      };
      default = {
        minVer = if (!args ? "nix" || !args.nix ? "minVer" || args.nix.minVer == "")
          then "25.05" else args.nix.minVer;
        cache = {
          enable = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "enable")
            then false else args.nix.cache.enable;
          ip = if (!args ? "nix" || !args.nix ? "cache" || !args.nix.cache ? "ip")
            then "" else args.nix.cache.ip;
        };
      };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options";
      type = types.submodule user;
      default = {
        name = user_name;
        pass = user_pass;
        fullname = if (!args ? "user" || !args.user ? "fullname") then "" else args.user.fullname;
        email = if (!args ? "user" || !args.user ? "email") then "" else args.user.email;
      };
    };

    git = lib.mkOption {
      type = types.submodule {
        options = {
          user = lib.mkOption {
            description = lib.mdDoc "Git user name";
            type = types.str;
            default = if (!args ? "git" || !args.git ? "user") then "" else args.git.user;
          };
          email = lib.mkOption {
            description = lib.mdDoc "Git email address";
            type = types.str;
            default = if (!args ? "git" || !args.git ? "email") then "" else args.git.email;
          };
          comment = lib.mkOption {
            description = lib.mdDoc "System build comment";
            type = types.str;
            default = if (!args ? "git" || !args.git ? "comment") then "" else args.git.comment;
          };
        };
      };
      default = {
        user = if (!args ? "git" || !args.git ? "user") then "" else args.git.user;
        email = if (!args ? "git" || !args.git ? "email") then "" else args.git.email;
        comment = if (!args ? "git" || !args.git ? "comment") then "" else args.git.comment;
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
            default = if (!args ? "net" || !args.net ? "gateway") then "" else args.net.gateway;
          };
          subnet = lib.mkOption {
            description = lib.mdDoc "Default subnet for the system";
            type = types.str;
            default = if (!args ? "net" || !args.net ? "subnet") then "" else args.net.subnet;
          };
          dns = lib.mkOption {
            description = lib.mdDoc "Default DNS for the system";
            type = types.submodule {
              options = {
                primary = lib.mkOption {
                  description = lib.mdDoc "Primary DNS IP";
                  type = types.str;
                };
                fallback = lib.mkOption {
                  description = lib.mdDoc "Fallback DNS IP";
                  type = types.str;
                };
              };
            };
            default = {
              primary = if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "primary")
                then "1.1.1.1" else args.net.dns.primary;
              fallback = if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "fallback")
                then "8.8.8.8" else args.net.dns.fallback;
            };
          };
        };
      };
      default = {
        bridge = { enable = false; };
        macvlan = { name = "host"; ip = "host"; };
        gateway = if (!args ? "net" || !args.net ? "gateway") then "" else args.net.gateway;
        subnet = if (!args ? "net" || !args.net ? "subnet") then "" else args.net.subnet;
        dns = {
          primary = if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "primary")
            then "1.1.1.1" else args.net.dns.primary;
          fallback = if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "fallback")
            then "8.8.8.8" else args.net.dns.fallback;
        };
      };
    };

    nics = lib.mkOption {
      description = lib.mdDoc "List of NIC options";
      type = types.listOf (types.submodule nic);
      default = if (!args ? "nics") then [] else (builtins.concatMap (x: [{
        name = if (!x ? "name") then "" else x.name;
        id = if (!x ? "id") then "" else x.id;
        link = if (!x ? "link") then "" else x.link;
        subnet = if (!x ? "subnet") then (if (!args ? "net" || !args.net ? "subnet")
          then "" else args.net.subnet) else x.subnet;
        gateway = if (!x ? "gateway") then (if (!args ? "net" || !args.net ? "gateway")
          then "" else args.net.gateway) else x.gateway;
        ip = if (!x ? "ip") then "" else x.ip;
        dns = {
          primary = if (!x ? "dns" || !x.dns ? "primary")
            then (if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "primary")
              then "1.1.1.1" else args.net.dns.primary) else x.dns.primary;
          fallback = if (!x ? "dns" || !x.dns ? "fallback")
            then (if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "fallback")
              then "8.8.8.8" else args.net.dns.fallback) else x.dns.fallback;
        };
      }]) args.nics);
    };

    services = lib.mkOption {
      description = lib.mdDoc "List of service secrets";
      type = types.listOf (types.submodule service);
      default = if (!args ? "services") then [] else (builtins.concatMap (x: [{
        name = if (!x ? "name") then "" else x.name;
        type = if (!x ? "type") then "cont" else x.type;
        user = if (!x ? "user") then "{}" else ({
          name = if (!x.user ? "name") then user_name else x.user.name;
          uid = if (!x.user ? "uid") then uid else x.user.uid;
          gid = if (!x.user ? "gid") then gid else x.user.gid;
          pass = if (!x.user ? "pass") then user_pass else x.user.pass;
          fullname = if (!x.user ? "fullname") then "" else x.user.fullname;
          email = if (!x.user ? "email") then "" else x.user.email;
        });
        nic = if (!x ? "nic") then "{}" else ({
          id = if (!x.nic ? "id") then "" else x.nic.id;
          link = if (!x.nic ? "link") then "" else x.nic.link;
          subnet = if (!x.nic ? "subnet") then (if (!args ? "net" || !args.net ? "subnet")
            then "" else args.net.subnet) else x.nic.subnet;
          gateway = if (!x.nic ? "gateway") then (if (!args ? "net" || !args.net ? "gateway")
            then "" else args.net.gateway) else x.nic.gateway;
          ip = if (!x.nic ? "ip") then "" else x.nic.ip;
          dns = {
            primary = if (!x.nic ? "dns" || !x.nic.dns ? "primary")
              then (if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "primary")
                then "1.1.1.1" else args.net.dns.primary) else x.nic.dns.primary;
            fallback = if (!x.nic ? "dns" || !x.nic.dns ? "fallback")
              then (if (!args ? "net" || !args.net ? "dns" || !args.net.dns ? "fallback")
                then "8.8.8.8" else args.net.dns.fallback) else x.nic.dns.fallback;
          };
        });
        port = if (!x ? "port") then 80 else x.port;
      }]) args.services);
    };

    smb = lib.mkOption {
      type = types.submodule smb;
      default = {
        enable = if (!args ? "smb" || !args.smb ? "enable") then false else args.smb.enable;
        user = if (!args ? "smb" || !args.smb ? "user") then "" else args.smb.user;
        pass = if (!args ? "smb" || !args.smb ? "pass") then "" else args.smb.pass;
        domain = if (!args ? "smb" || !args.smb ? "domain") then "" else args.smb.domain;
        entries = if (!args ? "smb" || !args.smb ? "entries") then [] else (builtins.concatMap (x: [{
          mountPoint = if (!x ? "mountPoint") then "" else x.mountPoint;
          remotePath = if (!x ? "remotePath") then "" else x.remotePath;
          user = if (!x ? "user" || x.user == "") then (if (!args ? "smb" || !args.smb ? "user")
            then "" else args.smb.user) else x.user;
          pass = if (!x ? "pass" || x.pass == "") then (if (!args ? "smb" || !args.smb ? "pass")
            then "" else args.smb.pass) else x.pass;
          domain = if (!x ? "domain" || x.domain == "") then (if (!args ? "smb" || !args.smb ? "domain")
            then "" else args.smb.domain) else x.domain;
          writable = if (!x ? "writable") then false else x.writable;
          options = if (!x ? "options") then [] else x.options;
        }]) args.smb.entries);
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
        enable = if (!args ? "nfs" || !args.nfs ? "enable") then false else args.nfs.enable;
        entries = if (!args ? "nfs" || !args.nfs ? "entries") then [] else args.nfs.entries;
      };
    };


  };
}
