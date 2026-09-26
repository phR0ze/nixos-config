# Workstation7 configuration
#
# ### Machine specs
# - ?
#
# ### Features
# - Basic deployment
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    host.boot.efi = true;
    host.nix.cache.enable = true;
    host.desktop.xfce.develop = true;

    devices.gpu.nvidia = { enable = true; open = true; };
    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;

    apps.network.deskflow.server.enable = true;
    apps.network.rustdesk.autostart = false;

    apps.dev.gemini.enable = true;
    apps.dev.opencode.enable = true;

    apps.games.roblox.enable = true;
    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
    apps.media.freecad.enable = true;

    services.native.smb.enable = true;
    virtualization.podman.enable = true;
    virtualization.qemu.host.enable = true;

    # Misc
    environment.systemPackages = with pkgs; [
      # Channel order: Front Left, Front Right, Front Center, LFE, Rear Left, Rear Right
      (writeShellScriptBin "audio-desktop" ''
        pactl set-sink-volume alsa_output.pci-0000_03_00.0.analog-surround-51 14% 18% 12% 12% 12% 12%
      '')
      (writeShellScriptBin "audio-headset" ''
        pactl set-sink-volume alsa_output.pci-0000_03_00.0.analog-surround-51 12% 12% 12% 12% 12% 12%
      '')
    ] ++ [
      xchm               # App for reading Microsoft help files for technical manuals
      synology-drive-client
      freetube
      #wiiload                 # Depends on freeimage which has bit rotted
      #wiimms-iso-tools        # Depends on freeimage which has bit rotted
      #gamecube-tools          # Depends on freeimage which has bit rotted
      quickemu
      zed-editor
      neovide
    ];
  };
}
