# clu configuration
#
# ### Details
# - NixOS automation
#---------------------------------------------------------------------------------------------------
{ stdenvNoCC, fetchFromGitHub, lib, }:

# Create the package from Github
stdenvNoCC.mkDerivation {
  name = "clu";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "phR0ze";
    repo = "nixos-config":
    rev = "main";
    hash = "";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp $src/clu $out/bin/
    chmod +x $out/bin/clu
  '';
};
