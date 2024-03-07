# Minimal wayland configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, args, ... }:
{
  imports = [
    ../cli
  ];

  #services.xserver.displayManager.startx.enable = true;

  environment.systemPackages = with pkgs; [

   # git                           # The fast distributed version control system
  ];
}

# vim:set ts=2:sw=2:sts=2
