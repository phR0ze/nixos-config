# Minimal configuration to start from essentially nothing
# * [NixOS minimal profile](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/minimal.nix)
# * [NixOS discourse on minimal OS](https://discourse.nixos.org/t/how-to-have-a-minimal-nixos/22652/3)
#---------------------------------------------------------------------------------------------------
{ lib, ... }: with lib;
{
  # Disable X11 by default
  environment.noXlibs = mkDefault true;

  # Disable all docs by default
  documentation.enable = mkDefault false;
  documentation.doc.enable = mkDefault false;
  documentation.info.enable = mkDefault false;
  documentation.man.enable = mkDefault false;
  documentation.nixos.enable = mkDefault false;

  # Disable default packges like Perl by default
  environment.defaultPackages = mkDefault [ ];

  # Disable one offs that pull things in
  environment.stub-ld.enable = false;
  programs.less.lessopen = mkDefault null;  # less pulls in Perl
  boot.enableContainers = mkDefault false;  # nixos-containers pulls in Perl
  programs.command-not-found.enable = mkDefault false;
  services.logrotate.enable = mkDefault false;
  services.udisks2.enable = mkDefault false;
  xdg.autostart.enable = mkDefault false;
  xdg.icons.enable = mkDefault false;
  xdg.mime.enable = mkDefault false;
  xdg.sounds.enable = mkDefault false;

  # Trim down the boot modules
  boot.initrd.includeDefaultModules = false;
}
# vim:set ts=2:sw=2:sts=2
