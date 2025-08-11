# Flutter options
#
# ### Getting started
# -
#
# ### References
# - 
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.development.flutter;
in
{
  options = {
    development.flutter = {
      enable = lib.mkEnableOption "Configure flutter dev environment";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Flutter Environment variables
    environment.sessionVariables.FLUTTER_ROOT="${pkgs.flutter}";
    environment.sessionVariables.DART_ROOT="${pkgs.flutter}/bin/cache/dart-sdk";
    environment.sessionVariables.CHROME_EXECUTABLE ="${pkgs.chromium}/bin/chromium";

    # Enable Android development
    development.android.enable = true;

    # Install flutter and dependencies
    environment.systemPackages = [
      pkgs.chromium             # Open source version of Chrome for Web dev
      pkgs.flutter              # Flutter support and its CLI
    ];
  };
}
