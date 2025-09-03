# Declares a machine type for reusability
#
# ### Features
# - args is the composed/overridden set of user arguments for this machine
#
# ### Defaults
# Defaults are handled differently at different levels in Nix
# - When no properties are set for 'machine.user' then the defaults for that option are used.
# - When properties are set e.g. 'machine.user.email' then the machine.user defaults are not used 
#   and instead the 'user.nix' sub module defaults are used.
# because of this odd behavior we must pass in the 'args' to each sub module as well so that all 
# defaults are set at every level to cover all the use cases.
#---------------------------------------------------------------------------------------------------
{ config, lib, args, f, ... }: with lib.types;
let
  smb = import ./smb.nix { inherit lib; };

  # Generate an id to be used as a default
  machine-id = pkgs.runCommandLocal "machine-id" {} ''
    ${pkgs.dbus}/bin/dbus-uuidgen > $out
  '';

  # Defaults to use for uniformity across the different default use cases
  user_name = args.user.name or "admin";
  user = {
    name = user_name;
    pass = if (!args ? "user" || !args.user ? "pass" || args.user.pass == "") then "admin" else args.user.pass;
    fullname = args.user.fullname or "admin";
    email = args.user.email or "admin";
    uid = config.users.users.${user_name}.uid;
    gid = config.users.groups."users".gid;
  };
in
{
  imports = [
    ./validate_machine.nix
  ];

  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine configuration definition";
      type = types.submodule {
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
              iso = args.type.iso or false;
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

          id = lib.mkOption {
            description = lib.mdDoc "Machine id for /etc/machine-id";
            type = types.str;
            default = if (!args ? "id" || args.id == "") then "${builtins.readFile machine-id}" else args.id;
          };

          profile = lib.mkOption {
            description = lib.mdDoc "Flake profile used during installation";
            type = types.str;
            default = if (!args ? "profile" || args.profile == "") then "xfce/desktop" else args.profile;
          };

          efi = lib.mkOption {
            description = lib.mdDoc "Enable EFI";
            type = types.bool;
            default = args.efi or false;
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
            default = args.drives or [];
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
            default = args.autologin or false;
          };

          bluetooth = lib.mkOption {
            description = lib.mdDoc "Enable bluetooth";
            type = types.bool;
            default = args.bluetooth or false;
          };

          resolution = lib.mkOption {
            description = lib.mdDoc "Display resolution";
            type = types.attrs;
            default = {
              x = args.resolution.x or 0;
              y = args.resolution.y or 0;
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
                        default = args.nix.cache.enable or false;
                      };
                      ip = lib.mkOption {
                        description = lib.mdDoc "IP address of the custom Nix binary cache";
                        type = types.str;
                        default = args.nix.cache.ip or "";
                      };
                      port = lib.mkOption {
                        description = lib.mdDoc "Port of the custom Nix binary cache";
                        type = types.int;
                        default = args.nix.cache.port or 5000;
                      };
                    };
                  };
                  default = {
                    enable = args.nix.cache.enable or false;
                    ip = args.nix.cache.ip or "";
                    port = args.nix.cache.port or 5000;
                  };
                };
              };
            };
            default = {
              minVer = if (!args ? "nix" || !args.nix ? "minVer" || args.nix.minVer == "")
                then "25.05" else args.nix.minVer;
              cache = {
                enable = args.nix.cache.enable or false;
                ip = args.nix.cache.ip or "";
                port = args.nix.cache.port or 5000;
              };
            };
          };

          git = lib.mkOption {
            type = types.submodule {
              options = {
                user = lib.mkOption {
                  description = lib.mdDoc "Git user name";
                  type = types.str;
                  default = args.git.user or "";
                };
                email = lib.mkOption {
                  description = lib.mdDoc "Git email address";
                  type = types.str;
                  default = args.git.email or "";
                };
                comment = lib.mkOption {
                  description = lib.mdDoc "System build comment";
                  type = types.str;
                  default = args.git.comment or "";
                };
              };
            };
            default = {
              user = args.git.user or "";
              email = args.git.email or "";
              comment = args.git.comment or "";
            };
          };

          # Networking options for the whole machine
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

                    Note, for bridge mode to work the primary nic id must be specified via "nics". This can 
                    be done via the "args.enc.json" or directly in the "configuration.nix" file.

                    1. args.enc.json example
                    {
                      "nics": [{
                        "name": "primary",
                        "id": "eth0"
                      }]
                    }

                    2. configuration.nix example
                    machine.nics = [{
                      name = "primary";
                      id = "eth0";
                    }];
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
                  default = args.net.gateway or "";
                };
                subnet = lib.mkOption {
                  description = lib.mdDoc "Default subnet for the system";
                  type = types.str;
                  default = args.net.subnet or "";
                };
                dns = lib.mkOption {
                  description = lib.mdDoc "Default DNS for the system";
                  type = types.submodule {
                    options = {
                      primary = lib.mkOption {
                        description = lib.mdDoc "Primary DNS IP";
                        type = types.str;
                        default = args.net.dns.primary or "1.1.1.1";
                      };
                      fallback = lib.mkOption {
                        description = lib.mdDoc "Fallback DNS IP";
                        type = types.str;
                        default = args.net.dns.fallback or "8.8.8.8";
                      };
                    };
                  };
                  default = {
                    primary = args.net.dns.primary or "1.1.1.1";
                    fallback = args.net.dns.fallback or "8.8.8.8";
                  };
                };
              };
            };
            default = {
              bridge = { enable = false; };
              macvlan = { name = "host"; ip = "host"; };
              gateway = args.net.gateway or "";
              subnet = args.net.subnet or "";
              dns = {
                primary = args.net.dns.primary or "1.1.1.1";
                fallback = args.net.dns.fallback or "8.8.8.8";
              };
            };
          };

          nfs = lib.mkOption {
            type = types.submodule {
              options = {
                enable = lib.mkOption {
                  description = lib.mdDoc "Enable NFS shares";
                  type = types.bool;
                  default = args.nfs.enable or false;
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
                  default = args.nfs.entries or [];
                };
              };
            };
            default = {
              enable = args.nfs.enable or false;
              entries = args.nfs.entries or [];
            };
          };

          # Networking options for specific NICs
          # ----------------------------------------------------------------------------------------------
          nics = lib.mkOption {
            description = lib.mdDoc "List of NIC definitions";
            type = types.listOf (types.submodule (import ./nic.nix { inherit lib; defaults = {}; }));
            default = if (args ? "nics") then (builtins.concatMap (x: [{
              name = x.name or "";
              id = x.id or "";
              link = x.link or "";
              subnet = x.subnet or (args.net.subnet or "");
              gateway = x.gateway or (args.net.gateway or "");
              ip = x.ip or "";
              dns = {
                primary = x.dns.primary or (args.net.dns.primary or "1.1.1.1");
                fallback = x.dns.fallback or (args.net.dns.fallback or "8.8.8.8");
              };
            }]) args.nics) else [];
          };

          smb = lib.mkOption {
            type = types.submodule smb;
            default = {
              enable = args.smb.enable or false;
              user = args.smb.user or user.name;
              pass = args.smb.pass or user.pass;
              domain = args.smb.domain or "";
              dirMode = args.smb.dirMode or "0755";
              fileMode = args.smb.fileMode or "0644";
              entries = if (args ? "smb" && args.smb ? "entries") then (builtins.concatMap (x: [{
                mountPoint = x.mountPoint or "";
                remotePath = x.remotePath or "";
                user = x.user or (args.smb.user or user.name);
                pass = x.pass or (args.smb.pass or user.pass);
                domain = if (x ? "domain" && x.domain != "") then x.domain else args.smb.domain or "";
                dirMode = if (x ? "dirMode" && x.dirMode != "") then x.dirMode else args.smb.dirMode or "0755";
                fileMode = if (x ? "fileMode" && x.fileMode != "") then x.fileMode else args.smb.fileMode or "0644";
                writable = x.writable or false;
                options = x.options or [];
              }]) args.smb.entries) else [];
            };
          };

          user = lib.mkOption {
            description = lib.mdDoc "User options";
            type = types.submodule (import ./user.nix { inherit lib; defaults = user; });
            default = user; # Used when machine.user is not set at all
          };
        };
      };
    };
  };
}
