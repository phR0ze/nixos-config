# Full desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [

    # System
    jdk17                               # Needed for: minecraft

    # Networking
    zoom-us                             # Video conferencing application

    # Utilities

    # Not available in NixOS
#    arcologout                         # Simple clean logout overlay from, repo: cyberlinux
#    kvantum                            # SVG-based theme engine for Qt5/Qt6 including Arc-Dark
#    wmctl                              # Rust X11 automation

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
  ];
}

# vim:set ts=2:sw=2:sts=2
