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
  virtualisation.qemu.host.enable = true;
  #homelab.lxconsole.enable = true;
  #homelab.qbittorrent.enable = true;
  #homelab.traefik.enable = true;
  #homelab.adguard.enable = true;
  #homelab.stirling-pdf.enable = true;
  #apps.media.tinyMediaManager.enable = true;
  #services.raw.minecraft.enable = true;

  environment.systemPackages = with pkgs; [
    mdadm                               # Linux Software RAID management
#    jdk17                               # Needed for: minecraft
  ];
}
