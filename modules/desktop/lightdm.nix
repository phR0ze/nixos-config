# Lightdm configuration
#
# NixOS uses /run/current-system/sw/share in place of /usr/share
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
let
  # 1. Build the package from the local files
  backgroundsPackage = pkgs.runCommandLocal "backgrounds" {} ''
    mkdir -p $out/share/backgrounds
    cp ${../../include/usr/share/backgrounds}/* $out/share/backgrounds
  '';
in
{

  # 2. Add the package to the /nix/store
  environment.systemPackages = [
    backgroundsPackage
  ];

  # 3. Link the package to the system path /run/current-system/sw 
  # - searches all packages that have paths matching the list and merge links them
  environment.pathsToLink = [
    "/share/backgrounds"  # /run/current-system/sw/share/backgrounds
  ];

  # Enable lightdm and set its default configuration
  services.xserver.displayManager.lightdm = {
    enable = true;
    background = "${backgroundsPackage}/share/backgrounds/sector-8_1600x900.jpg";
    greeters.slick = {
      enable = true;
      draw-user-backgrounds = true;
      theme.name = "Adwaita-dark";
      extraConfig = ''
        enable-hidpi=on
        show-a11y=false
        show-hostname=false
        show-keyboard=false
        clock-format=%a  %b  %d    %I:%M %P
      '';
    };
  };
}
