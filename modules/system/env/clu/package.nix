# clu package
#
# ### Source strategy: using `self` instead of `fetchFromGitHub`
#
# This package is the nixos-config repo itself, bundled as a Nix derivation so
# the ISO installer can run `clu install` with the exact configuration that was
# used to build the ISO.
#
# Previously this fetched from GitHub at a pinned commit hash, which meant the
# ISO always contained a stale snapshot requiring manual hash updates.
#
# The idiomatic Nix flake approach is to pass `self` — the flake's own source
# reference — from `base.nix` via `callPackage ... { src = self; }`. When Nix
# evaluates a flake, `self` is automatically bound to the exact source tree
# being built (the staged git content in the working directory). Passing it here
# as `src` means the bundled clu always matches the version you built the ISO
# from, with no manual maintenance required.
#---------------------------------------------------------------------------------------------------
{ stdenvNoCC, src, makeWrapper }:

stdenvNoCC.mkDerivation {
  name = "clu";
  version = "1.0.0";
  inherit src;

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -a $src/. $out/

    # Nix store sources are read-only (444/555); restore write bits so makeWrapper
    # can create $out/bin/clu and subsequent fixup phases can patch shebangs.
    chmod -R u+w $out

    chmod +x $out/clu
    makeWrapper $out/clu $out/bin/clu
  '';
}
