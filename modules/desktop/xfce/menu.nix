# XFCE menu options
#
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, ... }: with lib.types;
let
  f = pkgs.callPackage ../../../misc/funcs.nix { inherit lib; };
  cfg = config.services.xserver.desktopManager.xfce.menu;
  desktopType = (import ./desktop-type.nix { inherit options config lib pkgs args; }).desktopType;

  menuItems = pkgs.runCommandLocal "menu-items" {} ''
    set -euo pipefail
    mkdir -p "$out"

    override() {
      local source="$1"           # str: source nix store path to start from
      local name="$2"             # str: name of the desktop entry to use if set
      local exec="$3"             # str: execution command line to use if set
      local icon="$4"             # str: icon to use if set
      local startupNotify="$5"    # bool: notify on startup
      local terminal="$6"         # bool: enable a terminal window
      local categories="$7"       # str: categories to use for entry
      local comment="$8"          # str: comment to use for tool tip
      local hidden="$9"           # bool: mark the desktop entry to be hidden

      local target="$out/$(basename "$source")"
      cp "$source" "$out";
      chmod +w "$target"
      if [[ "$name" != "null" ]]; then sed -i -e "s|\(^Name=\).*|\1$name|" "$target"; fi
      if [[ "$exec" != "null" ]]; then sed -i -e "s|\(^Exec=\).*|\1$exec|" "$target"; fi
      if [[ "$icon" != "null" ]]; then sed -i -e "s|\(^Icon=\).*|\1$icon|" "$target"; fi
      sed -i -e "s|\(^StartupNotify=\).*|\1$startupNotify|" "$target"
      sed -i -e "s|\(^Terminal=\).*|\1$terminal|" "$target"
      if [[ "$categories" != "null" ]]; then sed -i -e "s|\(^Categories=\).*|\1$categories|" "$target"; fi
      if [[ "$comment" != "null" ]]; then sed -i -e "s|\(^Comment=\).*|\1$comment|" "$target"; fi
      if [[ "$hidden" == true ]];then echo "NoDisplay=true" >> "$target"; fi
    }

    ${lib.concatMapStringsSep "\n" (x: lib.escapeShellArgs [
      "override"
      x.source
      x.name
      x.exec
      x.icon
      (f.boolToStr x.startupNotify)
      (f.boolToStr x.terminal)
      x.categories
      x.comment
      (f.boolToStr x.noDisplay)
    ]) cfg.overrides}
  '';
in
{
  options = {
    services.xserver.desktopManager.xfce.menu.overrides = lib.mkOption {
      type = types.listOf desktopType;
      default = [];
      example = [
        { noDisplay = true; source = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop"; }
      ];
      description = lib.mdDoc "";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.overrides != []) {
      files.all.".local/share/applications".link = menuItems;
    })
  ];
}
