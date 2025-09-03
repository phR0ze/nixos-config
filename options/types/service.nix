# Declares service options type for reusability
#
# For use with docker containers mainly to make it easier to wrap and deploy them
#---------------------------------------------------------------------------------------------------
{ lib, defaults, ... }: with lib.types;
{
  options = {
    enable = lib.mkEnableOption "Deploy ${defaults.name or "target"} service";

    tag = lib.mkOption {
      description = lib.mdDoc "Service image 'tag' to use";
      type = types.str;
      default = "latest";
    };

    user = lib.mkOption {
      description = lib.mdDoc "User options for service";
      type = types.nullOr (types.submodule (import ./user.nix { inherit lib; defaults = defaults.user or {}; }));
      default = defaults.user or null;
    };

    nic = lib.mkOption {
      description = lib.mdDoc "NIC options for service";
      type = types.nullOr (types.submodule (import ./nic.nix { inherit lib; defaults = defaults.nic or {}; }));
      default = defaults.nic or null;
    };

    port = lib.mkOption {
      description = lib.mdDoc "Service port to use";
      type = types.int;
      default = defaults.port or 80;
    };
  };
}
