# Caddy with the caddy-dns/cloudflare module
#
# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{ lib, buildGoModule }:

buildGoModule rec {
  pname = "caddy";
  version = "2.11.4";

  src = ./include;

  vendorHash = "sha256-Lt43gRNb58Zmav7FJcmY/8X1dkEaKmPYvwn/8NvAQe8=";

  subPackages = [ "." ];

  ldflags = [ "-s" "-w" "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}" ];

  meta = with lib; {
    description = "Caddy build with the caddy-dns/cloudflare DNS-01 module included";
    homepage = "https://caddyserver.com";
    license = licenses.asl20;
    mainProgram = "caddy";
  };
}
