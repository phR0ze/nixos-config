# XDG options
#
# ### Details
# - Enabled by x11/default.nix
#---------------------------------------------------------------------------------------------------
{ options, config, lib, pkgs, args, f, ... }: with lib.types;
let
  cfg = config.services.xdg;
  desktopType = (import ./desktop-type.nix { inherit options config lib pkgs args; }).desktopType;

  # Handle overrides for XDG menu items
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
    ]) cfg.menu.itemOverrides}
  '';

  # Handle overrides for XDG menu directories
  menuDirs = pkgs.runCommandLocal "menu-dirs" {} ''
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
    ]) cfg.menu.dirOverrides}
  '';

in
{
  options = {
    services.xdg = {
      enable = lib.mkEnableOption "Install and configure xdg components";

      menu.itemOverrides = lib.mkOption {
        type = types.listOf desktopType;
        default = [];
        example = [
          {
            noDisplay = true;
            source = "${pkgs.xfce.libxfce4ui}/share/applications/xfce4-about.desktop";
          }
        ];
        description = lib.mdDoc "";
      };

      menu.dirOverrides = lib.mkOption {
        type = types.listOf desktopType;
        default = [];
        example = [
          {
            name = "Network";
            source = "${pkgs.xfce.libxfce4ui}/share/desktop-directories/xfce-network.directory";
          }
        ];
        description = lib.mdDoc "";
      };

    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {

      # Define which well known directories to create
      # xdg-user-dirs-update will run early in the login phase to create them
      # ~/.config/user-dirs.dirs
      environment.etc."xdg/user-dirs.defaults".text = ''
        DOWNLOAD=Downloads
        DOCUMENTS=Documents
        PROJECTS=Projects
        SCRIPTS=.local/bin
        MUSIC=Music
        PICTURES=Pictures
        VIDEO=Video
      '';

      environment.systemPackages = with pkgs; [
        xdg-user-dirs                       # Update XDG user dirs during login
        xdg-utils                           # Desktop integration utilities
      ];

      xdg = {
        autostart.enable = true;        # Defaults to true
        icons.enable = true;            # Defaults to true
        menus.enable = true;            # Defaults to true
        mime = {
          enable = true;                # Defaults to true

        #addedAssociations = {
        #  "application/pdf" = "firefox.desktop";
        #   "text/xml" = [
        #      "nvim.desktop"
        #      "vscode.desktop"
        #    ];
        #};
        #defaultAssociations = {
        #  "application/pdf" = "firefox.desktop";
        #  "text/xml" = [
        #    "nvim.desktop"
        #    "vscode.desktop"
        #   ];
        # };

        };
        #portal.enable = true;           # ??
        sounds.enable = true;           # Defaults to true

        #portal = {
        #  enable = true;
        #  wlr.enable = true;
        #  extraPortals = with pkgs; [
        #    xdg-desktop-portal-gtk
        #    xdg-desktop-portal-wlr
        #  ];
        #};
      };
    })

    # Configure menu item overrides
    (lib.mkIf (cfg.enable && cfg.menu.itemOverrides != []) {
      files.all.".local/share/applications".link = menuItems;
    })

    # Configure menu directory overrides
    (lib.mkIf (cfg.enable && cfg.menu.dirOverrides != []) {
      files.all.".local/share/desktop-directories".link = menuDirs;
    })
  ];
}
