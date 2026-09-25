# XFCE laptop bundle: enables xfce/laptop, which chains xfce/desktop + xfce/base + console/desktop
#
# ### Features
# - Directly installable: desktop with additional laptop tooling/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  layers.xfce.laptop.enable = true;
}
