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
    rev = "4ca742dd6ccd577a912f9bbf8993b2c8da5ce707";
    hash = "sha256-yDcHvLTzsORUEgTHg0KZhq3AsBbHlj1TpflXppFSjuI=";
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
