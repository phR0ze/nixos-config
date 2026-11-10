# firefight packages
#
# Builds the three firefight artifacts from one pinned source, exposed as an attribute set:
# - `server` - firefight-server, stores timers/clients and drives timer runs
# - `agent`  - firefight-agent, runs on each client machine and executes the timer actions
# - `app`    - the Flutter app, both the control deck (`--mode=server`) and client display
#              (`--mode=client`)
#
# `pubspec.lock.json` beside this file is `app/pubspec.lock` converted to JSON and must be
# regenerated whenever `rev` moves to a commit with a different lock file:
#   yq -o json eval '.' <firefight>/app/pubspec.lock > pubspec.lock.json
#
# The Flutter app needs Flutter 3.47+ (tray_manager/window_manager), newer than stable nixpkgs, so
# modules/nixpkgs.nix calls this with nixpkgs-unstable's `flutter`.
#---------------------------------------------------------------------------------------------------
{ lib, fetchFromGitHub, rustPlatform, flutter, pkg-config, alsa-lib, libx11, libxi, writeShellScript

# Build from a local checkout instead of the pinned source, see build.nix. Deliberately not named
# `src`: callPackage fills any argument whose name exists in the package set, and nixpkgs has a
# (throwing) `src` alias.
, firefightSrc ? null
}:
let
  version = "0.1.0";

  source = if firefightSrc != null then firefightSrc else fetchFromGitHub {
    owner = "phR0ze";
    repo = "firefight";
    rev = "bb59645a00ae41d5bfba3338aa54ab25782c9e41";
    hash = "sha256-tJtvYqRTAb4LQMONEkh7U25Zf0TKomGuw0Dd8fT/VHI=";
  };

  meta = {
    homepage = "https://github.com/phR0ze/firefight";
    platforms = lib.platforms.linux;
  };

  # Both binaries come from the same Cargo workspace and lock file, so they share a cargoHash.
  rustBin = crate: extra: rustPlatform.buildRustPackage ({
    pname = crate;
    inherit version;
    src = source;
    cargoHash = "sha256-u1QKJnt2LYlupUDhRo4j86YKrazdRQJFSn97Ye62fwQ=";
    cargoBuildFlags = [ "-p" crate ];
    # The test suite runs in the firefight repo; the e2e tests need a live loopback server.
    doCheck = false;
    meta = meta // { mainProgram = crate; };
  } // extra);

  # Dart build hooks (nativeapi, behind tray_manager/window_manager) run with a filtered environment
  # that drops PKG_CONFIG_PATH, so give them a pkg-config with the build's search path baked in.
  pkgConfigForHooks = writeShellScript "pkg-config-for-dart-hooks" ''
    export PKG_CONFIG_PATH="@PKG_CONFIG_PATH@''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    exec ${pkg-config}/bin/pkg-config "$@"
  '';
in
{
  server = rustBin "firefight-server" {
    meta = meta // {
      description = "firefight timer server";
      mainProgram = "firefight-server";
    };
  };

  agent = rustBin "firefight-agent" {
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ alsa-lib ];
    meta = meta // {
      description = "firefight client agent, runs timer actions on this machine";
      mainProgram = "firefight-agent";
    };
  };

  app = flutter.buildFlutterApplication {
    pname = "firefight-app";
    inherit version;
    src = "${source}/app";
    pubspecLock = lib.importJSON ./pubspec.lock.json;

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ libx11 libxi ];

    preBuild = ''
      mkdir -p "$TMPDIR/hook-bin"
      substitute ${pkgConfigForHooks} "$TMPDIR/hook-bin/pkg-config" \
        --replace-fail "@PKG_CONFIG_PATH@" "$PKG_CONFIG_PATH"
      chmod +x "$TMPDIR/hook-bin/pkg-config"
      export PATH="$TMPDIR/hook-bin:$PATH"
    '';

    meta = meta // {
      description = "firefight control deck and client display";
      mainProgram = "firefight";
    };
  };
}
