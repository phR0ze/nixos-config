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
    rev = "57e7f6077c65af7d5790ec7d3b400268ff8c2415";
    hash = "sha256-bPkaFRMO9OqXSju62OkzJZ3eEtGOTUPXpQn1QgqqV3s=";
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
