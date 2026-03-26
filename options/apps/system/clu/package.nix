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
{ pkgs, stdenvNoCC, src, makeWrapper }:

stdenvNoCC.mkDerivation {
  name = "clu";
  version = "1.0.0";
  inherit src;

  propagatedBuildInputs = with pkgs; [
    coreutils                           # stat provide file ownership
    gawk                                # awk provides text extraction
    git                                 # git is used to manage nixos-config
    gnused                              # sed is used to search and replace
    inxi                                # inxi is used to discover system details
    jq                                  # jg is used to generate and work with json
    openssh                             # scp is used to automated retrieving sops secrets
    psmisc                              # Ensure general purpose tooling available
    sops                                # sops is used to decrypt and encrypt secrets
    sudo                                # provides the ability to elevate privileges safely
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -a $src/. $out/

    makeWrapper $out/clu $out/bin/clu

    chmod +x $out/clu
  '';
}
