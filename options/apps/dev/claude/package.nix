# Claude Code configuration
#
# See README.md for update and build instructions.
#---------------------------------------------------------------------------------------------------
{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
  bubblewrap,
  procps,
  socat,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-code";
  version = "2.1.233";

  src = fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-tCUxbg9V18GLkIt3Nv/MYZHrBCXtjd5qtzIqEntj2ek=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  dontBuild = true;
  dontConfigure = true;

  # Stripping (part of the default fixup phase) corrupts the Bun SEA embedded bytecode
  # trailer, so it must stay disabled — matching nixpkgs' own claude-code package. With
  # stripping off, autoPatchelfHook can safely rewrite the ELF interpreter to a real
  # NixOS one, so the kernel loads it via normal PT_INTERP handling. That keeps
  # /proc/self/exe — and thus CLAUDE_CODE_EXECPATH — pointed at the real binary, no
  # manual ld.so invocation or system-wide nix-ld needed.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 claude $out/lib/claude-code/claude

    # We set our own WezTerm tab title (emoji + cwd) via `tt` instead of letting
    # Claude manage it, so CLAUDE_CODE_DISABLE_TERMINAL_TITLE is forced on here.
    makeWrapper $out/lib/claude-code/claude $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set CLAUDE_CODE_EXECPATH "$out/bin/claude" \
      --set CLAUDE_CODE_DISABLE_TERMINAL_TITLE 1 \
      --run 'command -v tt >/dev/null && source tt claude "$PWD"' \
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
