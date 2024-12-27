# Declares a machine type for reusability
#
# ### Features
# - _args is the composed/overridden set of user arguments for this machine
#---------------------------------------------------------------------------------------------------
{ lib, _args, ... }: with lib.types;
let
  nic = import ./nic.nix { inherit lib; };
  user = import ./user.nix { inherit lib; };
  type = import ./machine_type.nix { inherit lib; };
  vm = import ./vm.nix { inherit lib; };
  nfs_share = import ./nfs_share.nix { inherit lib; };
in
{
  options = {
    hostname = lib.mkOption {
      description = lib.mdDoc "Hostname";
      type = types.nullOr types.str;
      default = _args.hostname;
    };

    type = lib.mkOption {
      description = lib.mdDoc "Machine type";
      type = types.submodule type;
      default = { };
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options";
      type = types.submodule user;
      default = {
        name = _args.username;
        fullname = _args.fullname;
        email = _args.email;
        pass = _args.userpass;
      };
    };

    nic0 = lib.mkOption {
      description = lib.mdDoc "Nic options";
      type = types.submodule nic;
      default = { };
    };

    nic1 = lib.mkOption {
      description = lib.mdDoc "Nic options";
      type = types.submodule nic;
      default = { };
    };

    drive1-uuid = lib.mkOption {
      description = lib.mdDoc "Hard drive 1 UUID";
      type = types.nullOr types.str;
      default = "";
    };

    efi = lib.mkOption {
      description = lib.mdDoc "EFI is enabled";
      type = types.bool;
      default = false;
    };

    mbr = lib.mkOption {
      description = lib.mdDoc "BIOS mbr is enabled when not 'nodev'";
      type = types.nullOr types.str;
      default = "nodev";
    };

    arch = lib.mkOption {
      description = lib.mdDoc "System architecture";
      type = types.nullOr types.str;
      default = "x86_64-linux";
    };

    locale = lib.mkOption {
      description = lib.mdDoc "System locale";
      type = types.nullOr types.str;
      default = "en_US.UTF-8";
    };

    timezone = lib.mkOption {
      description = lib.mdDoc "System timezone";
      type = types.nullOr types.str;
      default = "America/Boise";
    };

    profile = lib.mkOption {
      description = lib.mdDoc "System profile used for original install";
      type = types.nullOr types.str;
      default = "generic/desktop";
    };

    autologin = lib.mkOption {
      description = lib.mdDoc "Enable autologin";
      type = types.bool;
      default = false;
    };

    bluetooth = lib.mkOption {
      description = lib.mdDoc "Enable bluetooth";
      type = types.bool;
      default = false;
    };

    nfs = lib.mkOption {
      description = lib.mdDoc "Enable NFS shares";
      type = types.bool;
      default = false;
    };

    nfsShares = lib.mkOption {
      description = lib.mdDoc "NFS shares to configure";
      type = types.listOf nfs_share;
      default = [ ];
    };

    stateVersion = lib.mkOption {
      description = lib.mdDoc "System state version";
      type = types.nullOr types.str;
      default = "24.05";
    };

    git = lib.mkOption {
      type = types.submodule {
        options = {
          user = lib.mkOption {
            description = lib.mdDoc "Git user name";
            type = types.nullOr types.str;
            default = null;
          };
          email = lib.mkOption {
            description = lib.mdDoc "Git email address";
            type = types.nullOr types.str;
            default = null;
          };
          comment = lib.mkOption {
            description = lib.mdDoc "System build comment";
            type = types.nullOr types.str;
            default = null;
          };
        };
      };
      default = null;
    };

    vms = lib.mkOption {
      description = lib.mdDoc "Virtual Machine definitions to host on this machine";
      type = types.listOf vm;
      default = [ ];
    };

    # Only applicable to VMs
    # ----------------------------------------------------------------------------------------------
    cores = lib.mkOption {
      description = lib.mdDoc "VM cores";
      type = types.int;
      default = 4;
    };

    diskSize = lib.mkOption {
      description = lib.mdDoc "VM disk size in MiB";
      type = types.int;
      default = 1 * 1024;
    };

    memorySize = lib.mkOption {
      description = lib.mdDoc "VM memory size in MiB";
      type = types.int;
      default = 4 * 1024;
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
      default = true;
    };

    resolution = lib.mkOption {
      description = lib.mdDoc "VM display resolution";
      type = types.attrs;
      default = {
        x = 1920;
        y = 1080;
      };
    };
  };
}
