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
    rev = "28bf52a089a836f2a724f902126a5c7ea77dff77";
    hash = "sha256-8GS4qcR4fsPpsMexpcHCRM/xnTHiWdIl1sSAh3XWE5g=";
  };

  propagatedBuildInputs = with pkgs; [
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
