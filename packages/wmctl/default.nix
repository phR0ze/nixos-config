# wmctl
#
#---------------------------------------------------------------------------------------------------
{ pkgs, ... }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "wmctl";
  version = "0.0.52";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-IbPklc3/h3nfX013KW1KrGNSXZGIONQvyB9vs9WLLdo=";
  };

  cargoHash = "sha256-b+w5v3+DTIfbUqM61bs0p0gSEZudA89Wp+RHfguvMPE=";
}
