# wmctl options
#
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: with lib.types;

pkgs.rustPlatform.buildRustPackage rec {
  pname = "wmctl";
  version = "0.0.49";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-Z9OsneHeV5JfNqmGF6RabQn3vmd1qmyylzcVCW40u2g=";
  };

  cargoHash = lib.fakeHash;
}
