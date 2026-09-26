# VM for testing out changes for Workstation7
# --------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  config = {
    host.type.vm = true;
    host.autologin = true;
    virtualization.qemu.guest = {
      enable = true;
      cores = 4;
      memorySize = 8;
      rootDrive.size = 40;
      network.macvtap = true;
    };

    # Existing worstation configuration
    # ----------------------------------------------------------------------------------------------
    host.nix.cache.enable = true;
    host.desktop.xfce.develop = true;

    #devices.gpu.nvidia = { enable = true; open = true; };
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
      xchm
      synology-drive-client
      freetube
      quickemu
      zed-editor
      neovide
    ];
  };
}
