# Options
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib;
  # We can leverage the write builders to create files in the user's home directory
  # https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeText

  #home.config.""
  #home.""

  # pkgs.writeShellScript

# Thoughts
# https://github.com/jakehamilton/config

#let
#
#  #cfg = config.apps.galculator;
#  #homedir = config.users.users.${args.settings.username}.home;
#in
#{
#  options.apps = mkOption {
#    description = "submodule example";
#    type = with types; attrsOf (submodule {
#      options = {
#        foo = mkOption {
#          type = int;
#        };
#        bar = mkOption {
#          type = str;
#        };
#      };
#    });
#  };
#}
let
  

  # Files activation script
  # 1. Check to if the file exists and if so delete it
  # 2. Copy over the new file
  activationScript = ''
    # Ensure xdg environment vars are set
    XDG_CONFIG_HOME=''${XDG_CONFIG_HOME:-$HOME/.config}
    XDG_CACHE_HOME=''${XDG_CACHE_HOME:-$HOME/.cache}
    XDG_DATA_HOME=''${XDG_DATA_HOME:-$HOME/.local/share}
    XDG_STATE_HOME=''${XDG_STATE_HOME:-$HOME/.local/state}

    rm -rf ''${XDG_CONFIG_HOME}/foobar
    cp -a ${../include/home} ''${XDG_CONFIG_HOME}/foobar
    #echo "this is a test 2" > ''${XDG_CONFIG_HOME}/foobar

    # xdg-desktop-settings generates this empty file but
    #rm -fv ''${XDG_CONFIG_HOME}/menus/applications-merged/xdg-desktop-menu-dummy.menu

    #trolltech_conf="''${XDG_CONFIG_HOME}/Trolltech.conf"
    #if [ -e "$trolltech_conf" ]; then
    #  ${getBin pkgs.gnused}/bin/sed -i "$trolltech_conf" -e '/nix\\store\|nix\/store/ d'
    #fi
  '';
in
{
  options.files

  # User activation scripts
  # ----------------------------------------------------------------------------------------------
  # system.userActivationScripts are executed by a systemd user service when a nixos-rebuild switch 
  # is run and likewise every boot since each boot activates the system anew.
  # 
  # - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/activation/activation-script.nix#L145
  #config.system.userActivationScripts.files = activationScript;
  config = {
    system.activationScripts.files =
      stringAfter [ "etc" "users" "groups" ] activationScript;
  };
}
