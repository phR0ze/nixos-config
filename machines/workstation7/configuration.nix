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
    ../../profiles/xfce/develop.nix
  ];

  config = {
    machine.type.bootable = true;
    machine.nix.cache.enable = true;
    devices.gpu.nvidia = { enable = true; open = true; };

    devices.printers.epson-wf7710 = true;
    devices.printers.brother-hll2405w = true;

    apps.network.deskflow.server.enable = true;
    apps.network.rustdesk.autostart = false;
    apps.network.tailscale = { enable = true; autoStart = true; };

    virtualisation.podman.enable = true;
    virtualisation.qemu.host.enable = true;

    apps.dev.claude.enable = true;
    apps.dev.gemini.enable = true;
    apps.dev.opencode.enable = true;

    apps.games.roblox.enable = true;
    apps.games.hedgewars.enable = true;
    apps.games.superTuxKart.enable = true;
    apps.media.freecad.enable = true;

    # Misc
    environment.systemPackages = [
      pkgs.xchm                     # App for reading Microsoft help files for technical manuals
      pkgs.synology-drive-client
      pkgs.freetube
      #pkgs.wiiload                 # Depends on freeimage which has bit rotted
      #pkgs.wiimms-iso-tools        # Depends on freeimage which has bit rotted
      #pkgs.gamecube-tools          # Depends on freeimage which has bit rotted
      pkgs.quickemu
      pkgs.zed-editor
      pkgs.rust-analyzer
      pkgs.neovide
    ];
  };
}
