# Minecraft server ooptions
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.minecraft-server;

in
{
  config = lib.mkIf (cfg.enable) {
    cfg.eula = true;            # means agreeing to Mojang's EULA: https://account.mojang.com/documents/minecraft_eula
    cfg.jvmOpts = "";

    #cfg.declarative = true;     # enables the serverProperties to take effect
    #cfg.serverProperties {
    #  gamemode = "survival";
    #  difficulty = 3;
    #};
  };
}
