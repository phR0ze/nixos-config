# dconf options
# - mkDconfKeyValue
# - toDconfINI
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.programs.dconf;

in
{
#  options = {
#    services.dconf.extra = {
#    };
#  };

  config = lib.mkIf (cfg.enable) {
  };
}
