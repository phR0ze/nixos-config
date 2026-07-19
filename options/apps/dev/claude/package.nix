# Claude Code configuration
#
# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  bubblewrap,
  procps,
  socat,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.215";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-I6/H3srYHFIwRx6SC/8v2eFrUoZjCdrWybxNIqcyoeU=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    # Store the binary unmodified — patchelf corrupts the Bun SEA embedded bytecode
    install -Dm755 claude $out/lib/claude-code/claude

    # Invoke via the glibc dynamic linker so we never touch the binary itself.
    # ld-linux supports --argv0 natively, which Bun SEA requires to identify itself.
    makeWrapper ${stdenv.cc.libc}/lib/ld-linux-x86-64.so.2 $out/bin/claude \
      --add-flags "--library-path ${lib.makeLibraryPath [ stdenv.cc.libc ]}" \
      --add-flags "--argv0 claude" \
      --add-flags "$out/lib/claude-code/claude" \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --unset DEV \
      --prefix PATH : ${
        lib.makeBinPath (
          [
            procps
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [
            bubblewrap
            socat
          ]
        )
      }

    runHook postInstall
  '';

  doInstallCheck = false;

  meta = {
    description = "Agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
    homepage = "https://github.com/anthropics/claude-code";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = lib.licenses.unfree;
    mainProgram = "claude";
    platforms = [ "x86_64-linux" ];
  };
})
