# PrismLauncher package with offline patch applied
#
# See README.md for patch update instructions.
#---------------------------------------------------------------------------------------------------
{ prismlauncher, tag ? "v11.0" }:
prismlauncher.override (prev: {
  prismlauncher-unwrapped = prev.prismlauncher-unwrapped.overrideAttrs (o: {
    patches = (o.patches or [ ]) ++ [ ./patches/${tag}/offline.patch ];
  });
})
