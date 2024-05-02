# XFCE workstation configuration
#
# ### Features
# - Directly installable: develop with extra tools and configuration
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./develop.nix
    #../../modules/services/barrier.nix
  ];

  #services.barriers.enable = true;
  #virtualization.virt-manager.enable = true;
}
