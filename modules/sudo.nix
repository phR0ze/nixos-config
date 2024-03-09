# Sudo configuration
#
# ### Features
# - Passwordless access for whell group
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  security.sudo = {
    enable = true;

    # Configure passwordless sudo access for 'wheel' group
    wheelNeedsPassword = false;
  };
}
