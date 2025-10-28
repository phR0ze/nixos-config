# clu configuration
#
# ### Details
# - NixOS automation
#---------------------------------------------------------------------------------------------------
{ lib, pkgs, stdenvNoCC, fetchFromGitHub, makeWrapper }:

# Create the package from Github
stdenvNoCC.mkDerivation {
  name = "clu";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "phR0ze";
    repo = "nixos-config";
    rev = "d09987a5472fc6e34840029d158efca958a44833";
    hash = "sha256-0twIUcCn4DZarMpX06k+2wQ3NjyLWOCQs+m16vTmhVg=";
  };

  propagatedBuildInputs = with pkgs; [
    coreutils                           # stat provide file ownership
    gawk                                # awk provides text extraction
    git                                 # git is used to manage nixos-config
    gnused                              # sed is used to search and replace
    inxi                                # inxi is used to discover system details
    jq                                  # jg is used to generate and work with json
    openssh                             # scp is used to automated retrieving sops secrets
    psmisc                              # Ensure general purpose tooling available
    sops                                # sops is used to decrypt and encrypt secrets
    sudo                                # provides the ability to elevate privileges safely
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -a $src/. $out/

    makeWrapper $out/clu $out/bin/clu

    chmod +x $out/clu
  '';
}
