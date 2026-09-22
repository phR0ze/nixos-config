# OpenCode configuration - built from source at a pinned commit, with local patches applied
#
# ### Why build from source instead of using the pre-built release?
# The pre-built binary approach cannot have local patches (see patches/) applied, since the
# release tarballs are already compiled. Building from source requires bun to run at build time,
# and bun crashes with "Illegal instruction" on CPUs without AVX2 - only build this on a machine
# known to have AVX2 (`grep avx2 /proc/cpuinfo`), since there is no remote/distributed builder
# configured for this flake.
#
# ### Update instructions
# 1. Find the commit to pin to (e.g. via https://github.com/anomalyco/opencode/commits/dev)
# 2. Update `rev` and `version` below, set `src.hash` to `lib.fakeHash`, then run a build to get
#    the real value from the hash-mismatch error:
#      nix build -f ./build.nix
# 3. Do the same for `node_modules.outputHash` (set to a dummy value, build, copy the real hash
#    from the error)
# 4. Rebase/refresh patches in patches/ against the new commit if they no longer apply cleanly
#---------------------------------------------------------------------------------------------------
{
  lib,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  makeBinaryWrapper,
  models-dev,
  nodejs,
  ripgrep,
  sysctl,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "1.18.32.p4";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "anomalyco";
    repo = "opencode";
    rev = "fe3f3a41f79ad292cc3c7c629567385a20ec5130";
    hash = "sha256-h5AmK9R0Clk+LT0Tmmfg7iXa6dXNlPi2I5xCjTDRdcg=";
  };

  patches = [
    ./patches/0001-feat-tui-configurable-sidebar-width.patch
    ./patches/0002-feat-tui-configurable-sidebar-position.patch
    ./patches/0003-feat-tui-home-path-completion.patch
    ./patches/0004-feat-tui-terminal-title-prefix.patch
  ];

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src patches;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu="*" \
        --frozen-lockfile \
        --filter ./ \
        --filter ./packages/app \
        --filter ./packages/codemode \
        --filter ./packages/core \
        --filter ./packages/effect-drizzle-sqlite \
        --filter ./packages/effect-sqlite-node \
        --filter ./packages/http-recorder \
        --filter ./packages/llm \
        --filter ./packages/opencode \
        --filter ./packages/plugin \
        --filter ./packages/protocol \
        --filter ./packages/schema \
        --filter ./packages/script \
        --filter ./packages/sdk \
        --filter ./packages/server \
        --filter ./packages/session-ui \
        --filter ./packages/tui \
        --filter ./packages/ui \
        --ignore-scripts \
        --no-progress \
        --os="*"

      bun --bun ./nix/scripts/canonicalize-node-modules.ts
      bun --bun ./nix/scripts/normalize-bun-binaries.ts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      find . -type d -name node_modules -exec cp -R --parents {} $out \;

      runHook postInstall
    '';

    # NOTE: Required else we get errors that our fixed-output derivation references store paths
    dontFixup = true;

    outputHash = "sha256-3jlFbwWRujEqL0TD9VKkMcRzXO9GD1+eIsfFGT5AsTA=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    bun
    nodejs
    installShellFiles
    makeBinaryWrapper
    writableTmpDirAsHomeHook
  ];

  postPatch = ''
    # NOTE: Relax Bun version check to be a warning instead of an error
    substituteInPlace packages/script/src/index.ts \
      --replace-fail 'throw new Error(`This script requires bun@''${expectedBunVersionRange}' \
                     'console.warn(`Warning: This script requires bun@''${expectedBunVersionRange}'
  '';

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/. .
    patchShebangs node_modules
    patchShebangs packages/*/node_modules

    runHook postConfigure
  '';

  env.MODELS_DEV_API_JSON = "${models-dev}/dist/_api.json";
  env.OPENCODE_DISABLE_MODELS_FETCH = true;
  env.OPENCODE_VERSION = finalAttrs.version;
  env.OPENCODE_CHANNEL = "stable";

  buildPhase = ''
    runHook preBuild

    cd ./packages/opencode
    bun --bun ./script/build.ts --single --skip-install
    bun --bun ./script/schema.ts config.json tui.json

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/opencode-*/bin/opencode $out/bin/opencode
    wrapProgram $out/bin/opencode \
     --prefix PATH : ${
       lib.makeBinPath (
         [
           ripgrep
         ]
         ++ lib.optionals stdenvNoCC.hostPlatform.isDarwin [
           sysctl
         ]
       )
     } \
    --set OPENCODE_DISABLE_AUTOUPDATE true

    install -Dm644 config.json $out/share/opencode/config.json
    install -Dm644 tui.json $out/share/opencode/tui.json

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd opencode \
      --bash <($out/bin/opencode completion) \
      --zsh <(SHELL=/bin/zsh $out/bin/opencode completion)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [
    "HOME"
    "OPENCODE_DISABLE_MODELS_FETCH"
  ];
  versionCheckProgramArg = "--version";

  passthru = {
    jsonschema = {
      config = "${placeholder "out"}/share/opencode/config.json";
      tui = "${placeholder "out"}/share/opencode/tui.json";
    };
  };

  meta = {
    description = "AI coding agent built for the terminal (patched)";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    maintainers = [ ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "opencode";
  };
})
