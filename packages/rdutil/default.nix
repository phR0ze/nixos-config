# rdutil
#
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rdutil";
  version = "1.0.1";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-cJPsX24fGiCcShF+ViVRIzgxl17uAd2g5iDgZLHuXDI=";
  };

  cargoHash = "sha256-pCZ15pwHPgoStBON/VyoSpx3bzj9aIvDDmyqc375aRA=";
}
