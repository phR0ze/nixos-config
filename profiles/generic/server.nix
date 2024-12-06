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

  # Home lab services
  homelab.traefik.enable = true;
  homelab.adguard.enable = true;
  homelab.stirling-pdf.enable = true;

  #programs.tinyMediaManager.enable = true;
  #services.minecraft-server.enable = true;
  #virtualization.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    mdadm                               # Linux Software RAID management
#    jdk17                               # Needed for: minecraft
  ];
}
