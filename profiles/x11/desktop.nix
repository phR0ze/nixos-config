# Full desktop independent X11 configuration
#
# ### Features
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jdk17                           # Needed for: minecraft
    zoom-us                         # Video conferencing application

    # Patch prismlauncher for offline mode
    (prismlauncher.override (prev: {
      prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [ ../../patches/prismlauncher/offline.patch ];
      });
    }))
  ];
}

# vim:set ts=2:sw=2:sts=2
