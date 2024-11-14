# XFCE server configuration
#
# ### Features
# - Directly installable: desktop with additional server tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./light.nix
  ];

  programs.tinyMediaManager.enable = true;
  #services.minecraft-server.enable = true;
  #virtualization.virt-manager.enable = true;

#  environment.systemPackages = with pkgs; [
#    jdk17                               # Needed for: minecraft
#  ];
}
