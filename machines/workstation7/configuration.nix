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
    # The CA0132's ALC898 HDA codec reports all jack pins as available=no because the
    # hardware doesn't implement jack presence detection properly. This cascades into two
    # problems:
    #
    # 1. WirePlumber's find-best-profile rejects all non-pro profiles (they show available=no)
    #    and falls back to pro-audio (raw AUX channels), breaking stereo/surround mixing.
    #
    # 2. WirePlumber's haveAvailableRoutes() returns false for the 5.1 sink because the
    #    "Line Out" EnumRoute covers card.profile.device=9 with available=no, causing the
    #    SB node to be excluded from default-sink candidate selection entirely.
    #
    # Root fix: HDA patch file loaded at module init time that overrides pins 0x14/0x15/0x16
    # (front/surround/center+LFE line-out jacks) from [Jack] (presence-detect) to [Fixed]
    # (always connected). This makes ALSA report the routes as available=yes, which cascades
    # correctly into WirePlumber profile and default-sink selection.
    #
    # The patch file is placed in /lib/firmware and referenced via options snd-hda-intel.
    # Card index 1 = the Creative HDA card (index 0 = USB audio, which loads first).
    hardware.firmware = [
      (pkgs.runCommand "snd-hda-creative-patch" {} ''
        mkdir -p $out/lib/firmware
        cat > $out/lib/firmware/hda-creative-sb.fw << 'EOF'
[codec]
0x10ec0899 0x11020041 0x1

[pincfg]
0x14 0x81014010
0x15 0x81011012
0x16 0x81016011
EOF
      '')
    ];

    boot.extraModprobeConfig = ''
      # Creative HDA card is at index 0 (NVIDIA HDMI audio loads as index 1).
      # USB audio devices load later as snd_usb_audio at indices 2+.
      # Apply pin config patch to override jack detection on output pins so that
      # ALSA (and in turn WirePlumber) sees them as always-connected.
      options snd-hda-intel patch=hda-creative-sb.fw
    '';

    # WirePlumber: force the 5.1 surround profile for the Creative card and boost
    # its session priority above USB audio devices (default ~1000) so it wins
    # default-sink selection. Profile selection and route availability are both fixed
    # by the kernel-level pin config patch above; these rules are belt-and-suspenders
    # to handle edge cases and ensure the correct profile is applied on every boot.
    services.pipewire.wireplumber.extraConfig."51-sound-blaster" = {
      "device.profile.priority.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_03_00.0"; } ];
          actions.update-props = {
            "priorities" = [ "output:analog-surround-51+input:analog-stereo" ];
          };
        }
      ];
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_03_00.0"; } ];
          actions.update-props = {
            "api.acp.auto-profile" = false;
            "api.acp.auto-port" = false;
          };
        }
        {
          matches = [ { "node.name" = "alsa_output.pci-0000_03_00.0.analog-surround-51"; } ];
          actions.update-props = {
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
