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

    # Sound Blaster CA0132 (HDA Creative / ALC898) fix
    #
    # The CA0132's HDA jack detection pins don't properly report presence, so WirePlumber
    # falls back to the raw "Pro Audio" profile (AUX0/AUX1 channels) instead of a normal
    # stereo profile. This causes apps like Firefox to connect in [init]/[corked] state and
    # produce no audio. We force the correct profile by targeting the card's stable PCI path
    # and give it a high session priority so it wins over USB audio devices.
    services.pipewire.wireplumber.extraConfig."51-sound-blaster" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_03_00.0"; } ];
          actions.update-props = {
            "api.acp.auto-profile" = false;
            "api.acp.auto-port" = false;
            # Force 5.1 surround + analog stereo input profile regardless of jack detection
            # state. The CA0132 reports all jacks as unavailable so WirePlumber falls back
            # to pro-audio without this override.
            "device.profile" = "output:analog-surround-51+input:analog-stereo";
            # Boost session priority well above USB audio devices (default ~1000)
            # so this card remains the default sink when USB devices are present.
            "priority.session" = 2000;
          };
        }
      ];
    };

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
