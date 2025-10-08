# Prismlauncher options
#
# ### Patches
# - provide offline support
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.apps.games.prismlauncher;
in
{
  options = {
    apps.games.prismlauncher = {
      enable = lib.mkEnableOption "Install and configure PrismLauncher";
      maxMemAlloc = lib.mkOption {
        description = lib.mdDoc "Max memory to allocate for minecraft client";
        type = types.int;
        default = 4096;
      };
      minMemAlloc = lib.mkOption {
        description = lib.mdDoc "Min memory to allocate for minecraft client";
        type = types.int;
        default = 512;
      };
      javaPath = lib.mkOption {
        description = lib.mdDoc "Path to use to find java";
        type = types.str;
        default = "java";
      };
      tag = lib.mkOption {
        description = lib.mdDoc "Version tag to match patches against";
        type = types.str;
        default = "v9.1";
      };
    };
  };

  config = lib.mkIf (cfg.enable) {

    # Patch the app then install it
    environment.systemPackages = with pkgs; [
      (prismlauncher.override (prev: {
        prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [ ./patches/${cfg.tag}/offline.patch ];
        });
      }))
    ];

    # Create the initial user configuration
    files.user.".local/share/PrismLauncher/prismlauncher.cfg".copy = (
      pkgs.writeText "prismlauncher.cfg" ''
        [General]
        ApplicationTheme=system
        ConfigVersion=1.2
        IconTheme=pe_colored
        JavaPath=${cfg.javaPath}
        Language=en_US
        LastHostname=${config.machine.hostname}
        MaxMemAlloc=${toString cfg.maxMemAlloc}
        MinMemAlloc=${toString cfg.minMemAlloc}
      ''
    );
  };
}
