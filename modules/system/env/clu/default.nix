# clu
# 
# ### Purpose
# - Exposes clu configuration options to the flake
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }:
let
  cfg = config.system.env.clu;
in
{
  options = {
    system.env.clu = {
      enable = lib.mkEnableOption "Install and configure clu";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      clu

      # handled by other optionl settings the in core/base layers
      # git
      # inxi
      # openssh

      coreutils                     # stat provide file ownership
      gawk                         # awk provides text extraction
      gnused                         # sed is used to search and replace
      jq                           # jg is used to generate and work with json
      psmisc                        # Ensure general purpose tooling available
      sops                        # sops is used to decrypt and encrypt secrets
      sudo                      # provides the ability to elevate privileges safely
      yq                           # yq is used to convert build-time args to/from yaml
    ];
  };
}
