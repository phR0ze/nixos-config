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
    hash = "sha256-X7YHDtsB+kqHFc8ieHTpmwjSjRLh6iy/Jg49ijK/79Q=";
  };

  cargoHash = "sha256-jjA+oPDXW+pvopCAgCN8QiBTla/71iZKINCYgXw9MCM=";
}
