# Homelab configuration
#
# ### Features
# - ?
# --------------------------------------------------------------------------------------------------
{ pkgs, lib, f, ... }:
let
  local_args = f.fromYAML ./args.dec.yaml;
in
{
  imports = [
    ../../options
    ../../profiles/server.nix
    ./hardware-configuration.nix
  ];

  assertions = [
    { assertion = (builtins.length local_args.username == "");
      message = "username: ${local_args.username}"; }
  ];
}
