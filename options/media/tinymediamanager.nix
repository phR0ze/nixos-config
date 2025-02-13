# Tiny media manager options
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.tinyMediaManager;

  tmmDesktopFilePackage = pkgs.runCommandLocal "tinyMediaManager" {} ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/tinymediamanager.desktop <<EOF
    [Desktop Entry]
    Version=1.1
    Type=Application
    Name=tinyMediaManager
    Icon=${tinymediamanager}/lib/tmm/tmm.png
    Exec=tinymediamanager
    Actions=
    Categories=Multimedia;
    EOF
  '';
in
{
  options = {
    programs.tinyMediaManager = {
      enable = lib.mkEnableOption "Install and configure Tiny Media Manager";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [
      pkgs.tinymediamanager
      tmmDesktopFilePackage
    ];

    # Trigger linking the package to the system path /run/current-system/sw 
    environment.pathsToLink = [
      "/share/applications"
    ];
  };
}
