# XFCE server configuration
#
# ### Features
# - Directly installable: generic/desktop with additional server tools and configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./desktop.nix
  ];

  virtualization.virt-manager.enable = true;
  #services.minecraft-server.enable = true;

  environment.systemPackages = with pkgs; [
    chromium                            # An open source web browser from Google
  ];
}
