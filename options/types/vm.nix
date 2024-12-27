# Declares VM options type for reusability
#
# https://nixos.org/manual/nixos/stable/#ex-submodule-direct
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib.types;
{
  options = {
    hostname = lib.mkOption {
      description = lib.mdDoc "VM hostname";
      type = types.str;
    };
  };
}
