# wmctl options
#
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: with lib.types;

pkgs.rustPlatform.buildRustPackage rec {
  pname = "wmctl";
  version = "0.0.48";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-PMqHMhIfMS5ZpZWU1qe08A2l6BZ7hs/4Il0zSnsAY5s=";
  };

  cargoHash = "sha256-iLhctiCDNpcTxoMrWwUWHBRc6X5rxSH9Jl2EDuktWmw=";
}
