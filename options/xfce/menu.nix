# XFCE menu options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../funcs { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.menu;

  menuItems = pkgs.runCommandLocal "menu-items" {} ''
    set -euo pipefail
    mkdir -p "$out"

    # Adding the NoDisplay=true value will hide it in the menu
    hide() {
      local target="$out/$(basename "$1")"
      cp "$1" "$out";
      chmod +w "$target"
      echo "NoDisplay=true" >> "$target"
    }

    # Set the `Categories` field to the desired value
    move() {
      local category="$1"
      local filename="$2"
      local target="$out/$(basename "$filename")"
      cp "$filename" "$out"
      chmod +w "$target"
      sed -i -e "s|\(^Categories=\).*|\1$category|" "$target"
    }

    ${lib.concatMapStringsSep "\n" (x: lib.escapeShellArgs [ "hide" x ]) cfg.hidden}
    ${lib.concatMapStringsSep "\n" (x: lib.escapeShellArgs [ "move" x.name x.target ]) cfg.category}
  '';
in
{
  options = {
    services.xserver.desktopManager.xfce.menu = {
      hidden = lib.mkOption {
        type = types.listOf types.path;
        default = [];
        description = lib.mdDoc "List of desktop files to hide in the menu";
      };
      category = lib.mkOption {
        type = types.listOf (submodule {
          options = {
            name = lib.mkOption {
              type = types.str;
              description = lib.mdDoc "Category name";
            };
            target = lib.mkOption {
              type = types.path;
              description = lib.mdDoc "Desktop file target";
            };
          };
        });
        default = [];
        example = [
          { name = "Office"; target = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop"; }
        ];
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.hidden != [] || cfg.category != []) {
      files.all.".local/share/applications".source = menuItems;
    })
  ];
}
