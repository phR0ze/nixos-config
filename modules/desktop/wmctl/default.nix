# wmctl options
#
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, ... }: with lib.types;

pkgs.rustPlatform.buildRustPackage rec {
  pname = "wmctl";
  version = "0.0.50";
  src = pkgs.fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-gRaa4SdD3j1VdCfjp00N1x5frSCVmd2cS+KAQTby4bY=";
  };

  cargoHash = "sha256-6u7Nt6BGganGJMRKh3D4IhHH9O+ZFuWpSG+UhhSQWeY=";
}
