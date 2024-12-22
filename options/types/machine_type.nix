# Declares deployment type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    develop = lib.mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Develop deployment type";
    };
    theater = lib.mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Theater deployment type";
    };
  };
}
