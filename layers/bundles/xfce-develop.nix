# XFCE development bundle: enables xfce/develop, which chains xfce/desktop + xfce/base + console/desktop
#
# ### Features
# - Directly installable: desktop with additional development tools/configs
# --------------------------------------------------------------------------------------------------
{ ... }:
{
  layers.xfce.develop.enable = true;
}
