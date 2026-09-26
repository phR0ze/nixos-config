# rdutil
#
# ### Details
# - Installs the custom `rdutil` CLI, see ./package.nix
# - Used to generate the encoded RustDesk permanent password for a host, i.e.
#   `rdutil encrypt <password> --key <host.id>`
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.apps.dev.rdutil;
in
{
  options = {
    apps.dev.rdutil = {
      enable = lib.mkEnableOption "Install the rdutil CLI";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      (pkgs.callPackage ./package.nix {})              # Call the local package
    ];
  };
}
