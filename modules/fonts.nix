# Font configuration
#
# ### Details
# - requires a GUI desktop environment
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  # Virtual console font will be chosen by the kernel
  # Default is 8x16 and Terminus 32 bold for larger resolutions
#  console = {
#    font = "ter-v24n";
#    packages = with pkgs; [ terminus_font ];
#  };

  fonts = {
    fontconfig.enable = true;
    fontDir.enable = true;          # Create shared font dir /run/current-system/sw/share/X11/fonts

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
}

# vim:set ts=2:sw=2:sts=2
