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

  # Assert all values are accounted for
  assertions = [
    { assertion = (local_args.username != "");
      message = "local args username needs to be set"; }
  ];

  # Configure deployment
  deployment.user.name = local_args.username;
  deployment.user.fullname = local_args.fullname;
  deployment.user.email = local_args.email;
}
