# Sudo configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  security.sudo = {
    enable = true;

    # Configure passwordless sudo access for 'wheel' group
    wheelNeedsPassword = false;

    # Non wheel groups can be modified with this syntax
#    extraRules = [
#      { commands = [{ command = "ALL"; options = [ "NOPASSWD" ];}]; groups = [ "wheel" ]; }
#    ];
  };
}

# vim:set ts=2:sw=2:sts=2
