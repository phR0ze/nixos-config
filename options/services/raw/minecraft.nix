# Minecraft server ooptions
#
# ### Server interaction
# The NixOS minecraft module has been setup to be able to interacted with via a socket 
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
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.minecraft;
in
{
  options = {
    services.raw.minecraft = {
      enable = lib.mkEnableOption "Install and configure minecraft server";
      levelSeed = lib.mkOption {
        type = types.str;
        default = "5705783928676095273";
        description = "Level seed";
      };
      memory = lib.mkOption {
        type = types.int;
        default = 4;
        description = "Amount of memory in GB to use";
      };
      gameMode = lib.mkOption {
        type = types.str;
        default = "survival";
        description = "Game mode to run in";
      };
      difficulty = lib.mkOption {
        type = types.str;
        default = "normal";
        description = "Game difficulty to run in";
      };
      lanOnly = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Set to false for account validation against minecraft.net";
      };
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    services.minecraft-server = {
      # This means agreeing to Mojang's EULA: https://account.mojang.com/documents/minecraft_eula
      eula = true;

      # Minecraft data files for state location
      dataDir = "/var/lib/minecraft";

      # Open ports in the server's firewall so others on the LAN can connect
      openFirewall = true;

      # JVM configuration
      # https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks?tab=readme-ov-file#server-g1gc
      jvmOpts = lib.concatStringsSep " " [
        "-Xms${toString cfg.memory}G -Xmx${toString cfg.memory}G"   # always bound the memory allowed the JVM
        "-XX:+UseG1GC"                                              # use the G1GC garbabe collector
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
        level-seed = cfg.levelSeed;             # world generates with random see if left blank
        gamemode = cfg.gameMode;                # survival | creative | adventure | spectator
        difficulty = cfg.difficulty;            # peaceful | easy | normal | hard
        online-mode = ! cfg.lanOnly;            # set lanOnly to false for account validation against minecraft.net
      };
    };
  };
}
