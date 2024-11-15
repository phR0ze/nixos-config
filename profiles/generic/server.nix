# XFCE server configuration
#
# ### Features
# - Directly installable: light with additional server tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./light.nix
  ];

  programs.tinyMediaManager.enable = true;
  #services.minecraft-server.enable = true;
  #virtualization.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    mdadm                               # Linux Software RAID management
#    jdk17                               # Needed for: minecraft
  ];
}
