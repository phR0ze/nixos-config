# Tiny media manager
# - https://gitlab.com/tinyMediaManager/tinyMediaManager
# - https://www.reddit.com/r/tinyMediaManager/comments/14yzalj/libmediainfo/
#
# ### License changes
# - Releae 4.1 changed the license to make FREE and PRO versions
# - https://gitlab.com/tinyMediaManager/tinyMediaManager/-/releases/tinyMediaManager-4.1
#---------------------------------------------------------------------------------------------------
{ stdenv, lib, pkgs, fetchurl, libmediainfo, libzen, jre, ... }:
let
  # Build a wrapper script that will configure an environment for Tiny Media Manager to run in
  tmm-bin = pkgs.writers.writeDash "tinymediamanager" ''
    TMMDIR=$(dirname $(readlink -f $0))/../lib/tmm
    tmp=$(mktemp -d) # workaround for unwriteable base directory
    trap 'rm -rf $tmp' INT TERM EXIT
    cd "$tmp"
    LD_LIBRARY_PATH=${lib.makeLibraryPath [ libmediainfo libzen ]} \
      ${jre}/bin/java \
        -Dappbase=https://www.tinymediamanager.org/ \
        -Dtmm.contentfolder=$HOME/.config/tmm \
        -classpath "$TMMDIR/tmm.jar:$TMMDIR/lib/*" \
        org.tinymediamanager.TinyMediaManager $@
  '';
in
stdenv.mkDerivation rec {
  pname = "tinymediamanager";
  version = "3.1.10";

  src = fetchurl {
    url = "https://gitlab.com/tinyMediaManager/tinyMediaManager/uploads/1e473ce8af04196db2c7097aad475d03/tmm_${version}_linux.tar.gz";
    sha256 = "sha256-Ox1uGHDHlleN5DlBKTsCbBxmJwr1n7KZkC1OSbtYrjs=";
  };
  sourceRoot = ".";

  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    install -D ${tmm-bin} $out/bin/tinymediamanager
    install -d $out/lib
    cp -r . $out/lib/tmm
  '';

  # NixOS license values can be found in nixpkgs/lib/licenses.nix
  meta = {
    homepage = https://www.tinymediamanager.org/;
    description = "tinyMediaManager is a media management tool that creats NFO files for use with Kodi";
    license = lib.licenses.asl20;
  };
}
