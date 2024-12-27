# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ config, pkgs, lib, args, f, ... }: with lib.types;
let
  # Apply external arg precedence to form the final set for the machine
  cfg = config.machine;
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/laptop.nix
    ./hardware-configuration.nix
  ];

  # Only one machine will be declared and defined because only one configuration.nix will be being
  # imported at a time for the target machine being configured.
  # Note: the _args being passed in will define all the defaults to be the given arguments
  options = {
    machine = lib.mkOption {
      description = lib.mdDoc "Machine arguments";
      type = types.submodule (import ../../options/types/machine.nix { inherit lib _args; });
    };
  };

  # Validate flake user args are set
  config = lib.mkMerge [
    {
      assertions = [
        # Validate user arguments
        { assertion = (cfg.user.name != ""); message = "Machine user.name not set"; }
        { assertion = (cfg.user.fullname != ""); message = "Machine user.fullname not set"; }
        { assertion = (cfg.user.email != ""); message = "Machine user.email not set"; }
        { assertion = (cfg.user.pass != ""); message = "Machine user.pass not set"; }

        # Validate user arguments
        { assertion = (cfg.hostname != ""); message = "Machine hostname not set"; }

        # System arguments
        { assertion = (cfg.drive1-uuid != ""); message = "Machine drive1-uuid not set"; }
      ];

        # Once the external args are transferred into the system options should be used
      #machine.hostname = _args.hostname;

      # User arguments
      machine.user.name = _args.username;
      machine.user.fullname = _args.fullname;
      machine.user.email = _args.email;
      machine.user.pass = _args.userpass;
    }

    # Networking arguments
    (lib.mkIf (_args.nic0 != "" && _args.ip0 != "") {
      machine.nic0.name = _args.nic0;
      machine.nic0.ip.full = _args.ip0;
      machine.nic0.ip.attrs = f.toIP _args.ip0;
      machine.nic0.subnet = _args.subnet;
      machine.nic0.gateway = _args.gateway;
      machine.nic0.dns.primary = _args.primary_dns;
      machine.nic0.dns.fallback = _args.fallback_dns;
    })

    # System arguments
    {
      machine.drive1-uuid = _args.drive1-uuid;
      machine.efi = _args.efi;
      machine.mbr = _args.mbr;
      machine.arch = _args.system;
      machine.locale = _args.locale;
      machine.profile = _args.profile;
      machine.timezone = _args.timezone;
      machine.autologin = _args.autologin;
      machine.bluetooth = _args.bluetooth;
      machine.nfs = _args.nfs;
      machine.stateVersion = _args.stateVersion;

      machine.git.user = _args.git_user;
      machine.git.email = _args.git_email;
      machine.git.comment = _args.comment;
    }
  ];
}
