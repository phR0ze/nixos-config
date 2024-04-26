# Minecraft server ooptions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.minecraft-server;

in
{
  config = lib.mkIf (cfg.enable) {
    cfg.eula = true;            # means agreeing to Mojang's EULA: https://account.mojang.com/documents/minecraft_eula

    # JVM configuration
    # https://github.com/brucethemoose/Minecraft-Performance-Flags-Benchmarks?tab=readme-ov-file#server-g1gc
    cfg.jvmOpts = lib.concatStringsSep " " [
      "-Xms4G -Xmx4G"                         # always bound the amount of memory allowed to the JVM
      "-XX:+UseG1GC"                          # use the G1GC garbabe collector
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
    #cfg.declarative = true;
    #cfg.serverProperties {
    #  gamemode = "survival";
    #  difficulty = 3;
    #};
  };
}
