# home-manager iso configuration
# --------------------------------------------------------------------------------------------------
{ config, lib, systemSettings, ... }:
{
  config = {
    home.file.".bash_profile".text = ''
      if [ ! if clu ]; then
        curl -sL -o clu https://raw.githubusercontent.com/phR0ze/nixos-config/main/clu
      fi
      chmod +x clu
      sudo ./clu -f https://github.com/phR0ze/nixos-config
    '';

#    modules = {
#      editors = {
#        nvim.enable = true;
#      };
#
#      shells = {
#        fish.enable = true;
#      };
#
#      terminals = {
#        foot.enable = true;
#      };
#    };
#
#    my.settings = {
#      host = "iso";
#      default = {
#        shell = "fish";
#        terminal = "foot";
#        browser = "firefox";
#        editor = "nvim";
#      };
#      fonts.monospace = "FiraCode Nerd Font Mono";
#    };
#
#    colorscheme = inputs.nix-colors.colorSchemes.catppuccin-mocha;

    home = {
      username = lib.mkDefault "nixos";
      homeDirectory = lib.mkDefault "/home/nixos";
      stateVersion = lib.mkDefault systemSettings.stateVersion;
    };
  };
}

# vim:set ts=2:sw=2:sts=2
