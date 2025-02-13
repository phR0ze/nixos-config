# Prismlauncher options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.games.prismlauncher;

  cfgfile = lib.mkIf cfg.enable (pkgs.writeText "prismlauncher.cfg" ''
    [General]
    ApplicationTheme=system
    ConfigVersion=1.2
    IconTheme=pe_colored
    JavaPath=${cfg.javaPath}
    Language=en_US
    LastHostname=${config.machine.hostname}
    MaxMemAlloc=${toString cfg.maxMemAlloc}
    MinMemAlloc=${toString cfg.minMemAlloc}
  '');
in
{
  options = {
    apps.games.prismlauncher = {
      enable = lib.mkEnableOption "Install and configure PrismLauncher";

      maxMemAlloc = lib.mkOption {
        type = types.int;
        default = 4096;
        description = lib.mdDoc "Max memory to allocate for minecraft client";
      };
      minMemAlloc = lib.mkOption {
        type = types.int;
        default = 512;
        description = lib.mdDoc "Min memory to allocate for minecraft client";
      };
      javaPath = lib.mkOption {
        type = types.str;
        default = "java";
        description = lib.mdDoc "Path to use to find java";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {

    environment.systemPackages = with pkgs; [
      (prismlauncher.override (prev: {
        prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ../../../patches/prismlauncher/offline.patch ];
        });
      }))
    ];

    files.user.".local/share/PrismLauncher/prismlauncher.cfg".copy = cfgfile;
  };
}
