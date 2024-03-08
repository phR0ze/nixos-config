# XDG configuration
#
# ### Details
# - https://nixos.wiki/wiki/Scanners
#---------------------------------------------------------------------------------------------------
{ pkgs, args, ... }:
{
  hardware.sane = {
    enable = true; 
    extraBackends = [
      pkgs.epkowa                         # Epson scanner support
      pkgs.hplipWithPlugin                # HP scanner support
      pkgs.utsushi                        # Generic scanner support
    ];
  };

  services.udev.packages = [
    pkgs.utsushi
  ];

  users.users.${args.settings.username}.extraGroups = [ "scanner" "lp" ];
}
