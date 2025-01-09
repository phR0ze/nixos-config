# Font configuration
#
# ### Details
# - centralizing all font configuration here
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, f, ... }: with lib.types;
let
  xcfg = config.services.xserver;
  xft = xcfg.xft;

  # Build the package from the local files
  customFonts = pkgs.runCommandLocal "fonts" {} ''
    mkdir -p $out/share/doc/X11/fonts
    mkdir -p $out/share/X11/fonts
    cp -r ${../../include/usr/share/doc/TTF}/* $out/share/doc/X11/fonts
    cp -r ${../../include/usr/share/fonts/TTF}/* $out/share/X11/fonts
  '';
in
{
  config = lib.mkIf (xcfg.enable) {

    # Install font related packages and custom fonts
    environment.systemPackages = with pkgs; [
      customFonts               # Custom local fonts
      font-manager              # GTK font viewer
    ];

    environment.pathsToLink = [
      "/share/doc/X11/fonts"  # /run/current-system/sw/share/doc/X11/fonts
      "/share/X11/fonts"  # /run/current-system/sw/share/X11/fonts
    ];

    # Virtual console font will be chosen by the kernel
    # Default is 8x16 and Terminus 32 bold for larger resolutions
  #  console = {
  #    font = "ter-v24n";
  #    packages = with pkgs; [ terminus_font ];
  #  };

    fonts = {
      fontDir.enable = true;              # Create shared font dir /run/current-system/sw/share/X11/fonts

      fontconfig = {
        enable = true;                    # Enable Fontconfig for X11 applications
        antialias = xft.antiAlias;        # Enable font antialising
        hinting = {
          enable = true;                  # Enable font hinting
          style = "full";                 # Configure slight hinting style
        };
        subpixel.rgba = xft.rgba;         # See option for more details
        defaultFonts.monospace = [
          "${xft.monospace} ${xft.monospaceStyle}"
          "Hack Nerd Font Mono Regular"
          "Source Code Pro Regular"
        ];
        defaultFonts.sansSerif = [
          "${xft.sans} ${xft.sansStyle}"
          "Source Sans Pro Regular"
          "Liberation Sans Regular"
        ];
        defaultFonts.serif = [
          "${xft.serif} ${xft.serifStyle}"
          "Source Serif Pro Regular"
          "Liberation Serif Regular"
        ];
        #defaultFonts.emoji = [ "JoyPixels" ];
        localConf = ''
          <match>
            <test name="family"><string>Helvetica</string></test>
            <edit binding="same" mode="assign" name="family"><string>DejaVu Sans Book</string></edit>
          </match>
        '';
      };

      packages = with pkgs; [
        nerd-fonts.hack               # Good mono development font
        nerd-fonts.inconsolata        # A monospace font for both screen and print
        nerd-fonts.inconsolata-go     # Awesome mono development font
        nerd-fonts.droid-sans-mono    # Good mono development font
        nerd-fonts.fira-code          # Mozilla foundation monospace font with programming ligatures
        nerd-fonts.terminess-ttf      # A clean fixed width font
        corefonts                     # Microsoft's TrueType core fonts for the Web
        dejavu_fonts                  # A typeface family based on the Bitstream Vera fonts
        font-awesome                  # Font Awesome OTF font
        google-fonts                  # Google Fonts includes: Fira, Roboto
        liberation_ttf                # Font replacements for Times New Roman, Arial and Courier New
        ubuntu_font_family            # Ubuntu font family
        source-code-pro               # Monospaced font family for coding environments
        source-sans-pro               # Sans variant of source pro fonts
        source-serif-pro              # Serif variant of source pro fonts
      ];
    };
  };
}
