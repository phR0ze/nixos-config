# rdutil options
#
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: with lib.types;

pkgs.rustPlatform.buildRustPackage rec {
  pname = "rdutil";
  version = "1.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-HDzIusEUAb1W1hA91tmFbRlJUjGfen9xs3ppPY56Vmw=";
  };

  buildInputs = [
    /etc/machine-id
  ];

  cargoHash = "sha256-U35u6n6xN6taruTXh7YGRLvyiXmGIHzGoT89wPVZldE=";
}
