# XFCE menu options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.menu;

  # Find the referenced desktop items, copy their contents to ~/.local/share/applications and set the 
  # key NoDisplay=true to tell XFCE not to show the item.
  hiddenMenuItems = pkgs.runCommandLocal "hidden-menu-items" {} ''
    set -euo pipefail
    hideMenuItem() {
      local dir="$out/.local/share/applications"
      local target="$dir/$1.desktop"
      mkdir -p "$dir"
      cp "/run/current-system/sw/share/applications/$1.desktop" "$target"
      echo "NoDisplay=true" >> "$target"
    }
    ${lib.concatMapStringsSep "\n" (item: lib.escapeShellArgs [
      "hideMenuItem"
      item
    ]) cfg.hidden}
  '';


in
{
  options = {
    services.xserver.desktopManager.xfce.menu = {
      hidden = lib.mkOption {
        type = types.listOf types.str;
        default = [];
        description = lib.mdDoc "List of desktop files to hide in the menu";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.hidden != []) {
      files.all.".local/share/applications".source = hiddenMenuItems;
    })
  ];
}
