# Minecraft server
#
# ### Description
# Vanilla Minecraft Java Edition server with configurable seed, game mode, difficulty, and memory.
#
# ### Server interaction
# The NixOS minecraft module has been setup to be able to be interacted with via a socket
# `/run/minecraft-server.stdin` for input and via the journal for output.
#
# Example to enable USER as an operator:
# 1. Listen for server output: `journalctl -u minecraft-server -f`
# 2. Feed it commands as root:
#    sudo su
#    echo "op USER" > /run/minecraft-server.stdin
#
# ### Awesome seeds
# * https://www.pcgamer.com/best-minecraft-seeds/
#   * The Dark Tower: 3477968804511828743
#   * Village Mansion Island: 5705783928676095273
#   * Ancient City: 7980363013909395816 (194, -44, -7)
#
# ### Directories
# - /var/lib/minecraft
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.services.native.minecraft;
in
{
  options = {
    services.native.minecraft = {
      enable = lib.mkEnableOption "Install and configure Minecraft server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 25565;
        description = lib.mdDoc "Port the Minecraft server listens on; opened in the firewall for LAN clients.";
      };

      levelSeed = lib.mkOption {
        type = lib.types.str;
        default = "5705783928676095273";
        description = lib.mdDoc "Level seed; the world generates with a random seed if left blank.";
      };

      memory = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = lib.mdDoc "Amount of memory in GB to give the JVM (both min and max heap).";
      };

      gameMode = lib.mkOption {
        type = lib.types.enum [ "survival" "creative" "adventure" "spectator" ];
        default = "survival";
        description = lib.mdDoc "Game mode to run in.";
      };

      difficulty = lib.mkOption {
        type = lib.types.enum [ "peaceful" "easy" "normal" "hard" ];
        default = "normal";
        description = lib.mdDoc "Game difficulty to run in.";
      };

      lanOnly = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = lib.mdDoc "Set to false for account validation against minecraft.net (online mode).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-server = {
      enable = true;

      # This means agreeing to Mojang's EULA: https://account.mojang.com/documents/minecraft_eula
      eula = true;

      # Minecraft data files for state location
      dataDir = "/var/lib/minecraft";

      # Open server-port in the firewall so others on the LAN can connect
      openFirewall = true;

      # JVM configuration
      # https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks?tab=readme-ov-file#server-g1gc
      jvmOpts = lib.concatStringsSep " " [
        "-Xms${toString cfg.memory}G -Xmx${toString cfg.memory}G"   # always bound the memory allowed the JVM
        "-XX:+UseG1GC"                                              # use the G1GC garbage collector
        "-XX:MaxGCPauseMillis=130"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=28"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=20"
        "-XX:G1MixedGCCountTarget=3"
        "-XX:InitiatingHeapOccupancyPercent=10"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=0"
        "-XX:SurvivorRatio=32"
        "-XX:MaxTenuringThreshold=1"
        "-XX:G1SATBBufferEnqueueingThresholdPercent=30"
        "-XX:G1ConcMarkStepDurationMillis=5"
        "-XX:G1ConcRSHotCardLimit=16"
        "-XX:G1ConcRefinementServiceIntervalMillis=150"
      ];

      # Enable serverProperties to take effect
      declarative = true;
      serverProperties = {
        server-port = cfg.port;
        level-seed = cfg.levelSeed;
        gamemode = cfg.gameMode;
        difficulty = cfg.difficulty;
        online-mode = ! cfg.lanOnly;
      };
    };
  };
}
