# clu configuration
#
# ### Details
# - NixOS automation
#---------------------------------------------------------------------------------------------------
{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper }:

# Create the package from Github
stdenvNoCC.mkDerivation {
  name = "clu";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "phR0ze";
    repo = "nixos-config";
    rev = "main";
    hash = "sha256-y9A4MtjWyaKpzEVRnCa3dYOE3t83j02BGR9qkMbzvWY=";
  };

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
