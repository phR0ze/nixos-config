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
    rev = "a17face83ce1f27c4b64343903d311eaa36d4efb";
    hash = "sha256-4E0SsBSbxgfFghXR3eDB5RiWzhRtVt+jjE4ab26/sHE=";
  };

  propagatedBuildInputs = with pkgs; [
    gawk                                # awk provides text extraction
    git                                 # git is used to manage nixos-config
    gnused                              # sed is used to search and replace
    inxi                                # inxi is used to discover system details
    jq                                  # jg is used to generate and work with json
    openssh                             # scp is used to automated retrieving sops secrets
    psmisc                              # Ensure general purpose tooling available
    sops                                # sops is used to decrypt and encrypt secrets
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
