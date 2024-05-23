# Xnview options
# - no longer using this as Thunar does a better job
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.programs.xnviewmp;

  # Fetch and convert the icon
  icon = pkgs.runCommand "xnviewmp-icon" { 
    nativeBuildInputs = [ pkgs.imagemagick ];
    src = pkgs.fetchurl {
      url = "https://www.xnview.com/img/app-xnviewmp-512.webp";
      sha256 = "10zcr396y6fj8wcx40lyl8gglgziaxdin0rp4wb1vca4683knnkd";
    };
  } ''
    mkdir -p $out/share/icons/hicolor/512x512/apps
    convert $src $out/share/icons/hicolor/512x512/apps/xnviewmp.png
  '';

  # Build XnViewMP from AppImage
  xnviewmp = pkgs.appimageTools.wrapType2 rec {
    name = "xnviewmp";
    version = "1.7.0";
    src = pkgs.fetchurl {
      url = "https://download.xnview.com/XnView_MP.glibc2.17-x86_64.AppImage";
      hash = "sha256-0yj4wo0iWhvsAKsIUHzZOpouTOkcLU3gJMkq0Hmrqpw=";
    };
    extraPkgs = pkgs: with pkgs; [
      qt5.qtbase
    ];
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      cat > $out/share/applications/xnviewmp.desktop <<EOF
      [Desktop Entry]
      Type=Application
      Name=XnView MP
      Icon=xnviewmp
      Exec=xnviewmp %F
      Categories=Graphics;
      EOF
      
      # Ensure the icon is copied to the right place
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${icon}/share/icons/hicolor/512x512/apps/xnviewmp.png $out/share/icons/hicolor/512x512/apps/
    '';
  };

in
{
  options = {
    programs.xnviewmp = {
      enable = lib.mkEnableOption "Install and configure xnviewmp";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = with pkgs; [ xnviewmp ];
    files.all.".config/xnviewmp/xnview.ini".weakCopy = ../../include/home/.config/xnviewmp/xnview.ini;
  };
}
