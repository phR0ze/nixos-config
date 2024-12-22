# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, args, f, ... }:
let
  # Apply external arg precedence to form the final set for the machine
  _args = args // (import ./args.nix) // (f.fromYAML ./args.dec.yaml);
in
{
  imports = [
    ../../profiles/server.nix
    ./hardware-configuration.nix
  ];

  # Once the external args are transferred into the system options should be used
  machine.hostname = _args.hostname;
  machine.isVM = _args.isVM;
  machine.isISO = _args.isISO;

  # User arguments
  machine.user.name = _args.username;
  machine.user.fullname = _args.fullname;
  machine.user.email = _args.email;
  machine.user.pass = _args.userpass;

  # Networking arguments
  machine.nic0.name = _args.nic0;
  machine.nic0.ip.full = _args.ip0;
  machine.nic0.ip.attrs = f.toIP _args.ip0;
  machine.nic0.subnet = _args.subnet;
  machine.nic0.gateway = _args.gateway;
  machine.nic0.dns.primary = _args.primary_dns;
  machine.nic0.dns.fallback = _args.fallback_dns;

  # System arguments
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

  # Virtual machine arguments
  machine.cores = _args.cores;
  machine.diskSize = _args.diskSize * 1024;
  machine.memorySize = _args.memorySize * 1024;
  machine.graphics = _args.graphics;
  machine.resolution = { x = _args.resolution.x; y = _args.resolution.y; };

  machine.vms = [];
}
