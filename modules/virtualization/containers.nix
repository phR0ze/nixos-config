# Container configuration
#
# ### Details
# - https://nixos.org/manual/nixos/unstable/#sec-declarative-containers
# NixOS provides a mechanism to run other NixOS instances as containers. The container shares the Nix 
# store of the host, making container creation very efficient.
#---------------------------------------------------------------------------------------------------
{ args, ... }:
{
#  containers.database = {
#    config = { config, pkgs, ... }: {
#      services.postgresql.enable = true;
#      services.postgresql.package = pkgs.postgresql_14;
#    };
#  };
}
