# rdutil
#
# Custom Rust CLI used to encrypt a RustDesk permanent password for a specific host id, see
# `modules/apps/network/rustdesk`. Built from the upstream tagged release.
#---------------------------------------------------------------------------------------------------
{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage rec {
  pname = "rdutil";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "phR0ze";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-cJPsX24fGiCcShF+ViVRIzgxl17uAd2g5iDgZLHuXDI=";
  };

  cargoHash = "sha256-gbwt5Z41fLVH5Ms8LXdN7ZJr5jcJk0Ojjw20B4LQ+kg=";

  meta = {
    description = "RustDesk utility for encrypting permanent passwords";
    homepage = "https://github.com/phR0ze/rdutil";
    platforms = lib.platforms.linux;
    mainProgram = "rdutil";
  };
}
