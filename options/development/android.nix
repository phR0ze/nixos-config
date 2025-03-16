# Android options
#
# ### Getting started
# - run: sdkmanager --list
# ### References
# - [Android API levels](https://apilevels.com/)
# - [Android env - NixOS Manual](https://nixos.org/manual/nixpkgs/unstable/#android)
# - [Android app deloyments](https://sandervanderburg.blogspot.com/2014/02/reproducing-android-app-deployments-or.html)
# - [Build and emulate Android apps](http://sandervanderburg.blogspot.com/2012/11/building-android-applications-with-nix.html)
#---------------------------------------------------------------------------------------------------
{ config, lib, pkgs, ... }: with lib.types;
let
  cfg = config.development.android;
  machine = config.machine;

  # Install Android SDK and NDK with custom versions and components
  # Android 10, API 29, 
  # Android tools/platform/build tools should be latest version
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    # These default to latest or false so we're good unless it doesn't work
    # pkgs/development/mobile/androidenv/compose-android-packages.nix
    #toolsVersion = "26.1.1";
    #platformToolsVersion = "33.0.3";
    #buildToolsVersions = [ "30.0.3" ];
    #emulatorVersion = "34.1.9";
    #cmakeVersions = [ "3.10.2" ];
    #ndkVersions = [ "22.0.7026061" ];
    includeNDK = true;
    includeEmulator = true;
    platformVersions = [ "29" ];
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
    includeSources = false;
    includeSystemImages = false;
    includeExtras = [
      "extras;google;gcm"
    ];

    # Accepts all license for Flutter if `android_sdk.accept_licenses = true` is set.
    # https://github.com/NixOS/nixpkgs/issues/267263#issuecomment-1833769682
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"            
    ];
  };
  androidSdk = androidComposition.androidsdk;
in
{
  options = {
    development.android = {
      enable = lib.mkEnableOption "Install and configure android tooling";
    };
  };
 
  config = lib.mkIf (cfg.enable) {

    # Enable ADB and provide user access
    programs.adb.enable = true;
    users.users.${machine.user.name}.extraGroups = [ "adbusers" ];

    # Set Android Environment variables
    environment.sessionVariables.ANDROID_HOME = "${androidSdk}/libexec/android-sdk";

    # Install custon Android SDK
    environment.systemPackages = [
      pkgs.jdk                # Android dependency
      androidSdk              # Custom Android SDK
    ];
  };
}
