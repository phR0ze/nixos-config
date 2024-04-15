# XFCE development configuration
#
# ### Features
# - Directly installable: xfce/desktop with additional development tools and configuration
# - barrier server configuration
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  imports = [
    ./desktop.nix
    ../../modules/desktop/x11/develop.nix
  ];

  # Additional programs and services
  services.barriers.enable = true;      # Enable the barrier server and client
}
