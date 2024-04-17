# Font configuration
#
# ### Details
# - centralizing all font configuration here
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  xcfg = config.services.xserver;
  xfceCfg = xcfg.desktopManager.xfce;

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
        antialias = xcfg.xft.antiAlias;   # Enable font antialising
        hinting = {
          enable = true;                  # Enable font hinting
          style = "full";                 # Configure slight hinting style
        };
        subpixel.rgba = xcfg.xft.rgba;    # See option for more details
        defaultFonts.monospace = [
          "${xcfg.xft.monospace} ${xcfg.xft.monospaceStyle}"
          "DejaVu Sans Mono Book"
          "Hack Nerd Font Mono Regular"
          "Source Code Pro Regular"
        ];
        defaultFonts.sansSerif = [
          "${xcfg.xft.sans}"
          "Source Sans Pro Regular"
          "Liberation Sans Regular"
        ];
        defaultFonts.serif = [
          "${xcfg.xft.serif}"
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
        (nerdfonts.override {
          fonts = [
            "Hack"                    # Hand groomed/optically balanced typeface based on Bitstream Vera Mono
            "InconsolataGo"           # Best monospaced terminal font for coding
            "DroidSansMono"
          ];
        })
        corefonts                     # Microsoft's TrueType core fonts for the Web
        dejavu_fonts                  # A typeface family based on the Bitstream Vera fonts
        fira-code-nerdfont            # Mozilla foundation monospace font with programming ligatures
        font-awesome                  # Font Awesome OTF font
        inconsolata-nerdfont          # A monospace font for both screen and print
        liberation_ttf                # Font replacements for Times New Roman, Arial and Courier New
        ubuntu_font_family            # Ubuntu font family
        source-code-pro               # Monospaced font family for coding environments
        source-sans-pro               # Sans variant of source pro fonts
        source-serif-pro              # Serif variant of source pro fonts
        roboto-mono                   # Google Roboto Mono fonts
        roboto                        # Google Roboto family of fonts
        terminus-nerdfont             # A clean fixed width font
      ];
    };
  };
}
