{ lib, pkgs, ... }
{
  # Stopped on Bs

  # https://github.com/aaronjanse/dotfiles/blob/master/configuration.nix 
  # ------------------------------------------------------------------------------------------------
  hardware.enableRedistributableFirmware = true;
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
    driSupport32Bit = true;
  };

  services.journald.extraConfig = "MaxRetentionSec=1week";
  programs.adb.enable = true;
  users.defaultUserShell = pkgs.fish;
  environment.variables.EDITOR = "${pkgs.kakoune}/bin/kak";
  
  networking = {
    hostName = "xps-ajanse";
    networkmanager.enable = true;
    nameservers = pkgs.lib.mkForce [ "193.138.218.74" ]; # mullvad

    iproute2.enable = true;

    wireguard = {
      enable = true;
      interfaces.wg0 = secrets.wireguard;
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 ];
      allowedUDPPorts = [ 51820 41641 ];
      trustedInterfaces = [ "wg0" ];
    };
    hosts = {
      "192.168.1.249" = [ "BRW707781875760.local" ];
      "172.31.98.1" = [ "aruba.odyssys.net" ];
      "127.0.0.1" = [ "localhost.dev" "local.metaculus.com" ];
    };
  };
 
  hardware.bluetooth.enable = true;
  services.blueman.enable = true; 

  services.dbus.packages = [ pkgs.blueman pkgs.foliate ];

  console = {
    earlySetup = true;
    font = "sun12x22";
    colors = theme.colors16;
  };

  systemd.user.services.xinput-config = {
    description = "configure xinput for xps";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    script = ''
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Accel Speed" 0.55 || true
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SynPS/2 Synaptics TouchPad" "libinput Tapping Drag Enabled" 0 || true
      ${pkgs.xorg.xinput}/bin/xinput set-prop "SysPS/2 Synaptics TouchPad" "libinput Disable While Typing Enabled" 0 || true
    '';
  };

  
  /* Printing */

  services.printing.enable = true;
  services.printing.drivers = [ pkgs.brlaser pkgs.mfcl2740dwlpr pkgs.mfcl2740dwcupswrapper ];
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

}
