# Tiny media manager options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.tinyMediaManager;
  tinymediamanager = pkgs.callPackage ./default.nix { };

in
{
  options = {
    programs.tinyMediaManager = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Install tiny media manager";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      tinymediamanager
    ];
  };
}
