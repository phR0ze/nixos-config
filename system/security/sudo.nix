# Sudo configuration
#---------------------------------------------------------------------------------------------------
{ ... }:
{
  security.sudo = {
    enable = true;
    extraRules = [
      # Configure passwordless sudo access for 'wheel' group
      { commands = [{ command = "ALL"; options = [ "NOPASSWD" ];}]; groups = [ "wheel" ]; }
    ];
  };
}

# vim:set ts=2:sw=2:sts=2
