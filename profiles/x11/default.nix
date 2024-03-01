# Minimal desktop independent X11 configuration
#
# ### Features
# -
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ../cli
  ];

  environment.systemPackages = with pkgs; [

   # git                           # The fast distributed version control system
  ];
}

# vim:set ts=2:sw=2:sts=2
