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
  virtualization.host.enable = true;
  virtualization.virt-manager.enable = true;
  #homelab.lxconsole.enable = true;
  #homelab.qbittorrent.enable = true;
  #homelab.traefik.enable = true;
  #homelab.adguard.enable = true;
  #homelab.stirling-pdf.enable = true;

  #programs.tinyMediaManager.enable = true;
  #services.minecraft-server.enable = true;

  environment.systemPackages = with pkgs; [
    mdadm                               # Linux Software RAID management
#    jdk17                               # Needed for: minecraft
  ];
}
