# Sunshine configuration
#
# ### Description
# [Sunshine](https://github.com/LizardByte/Sunshine) is a self-hosted game stream host for Moonlight. 
# Offering low latency, cloud gaming server capabilities with support for AMD, Intel, and Nvidia GPUs 
# for hardware encoding. Software encoding is also available. You can connect to Sunshine from any 
# Moonlight client on a variety of devices. A web UI is provided to allow configuration, and client 
# pairing, from your favorite web browser. Pair from the local server or any mobile device.
#
# --------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.services.raw.sunshine;
  machine = config.machine;
in
{
  options = {
    services.raw.sunshine = {
      enable = lib.mkEnableOption "Install and configure Sunshine";
    };
  };
 
  config = lib.mkIf (cfg.enable) {
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
    };
  };
}
