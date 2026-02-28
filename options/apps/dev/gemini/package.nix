{
  lib,
  stdenv,
  buildNpmPackage,
  fetchFromGitHub,
  jq,
  pkg-config,
  clang_20,
  libsecret,
  ripgrep,
  nodejs_22,
  makeWrapper,
  nix-update-script,
}:

buildNpmPackage (finalAttrs: {
  pname = "gemini-cli";
  version = "0.31.0";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-huPd4W7Jf4/dZshWElicYpcHhktE83wPs/z5jVYwynM=";
  };

  nodejs = nodejs_22;

  npmDepsHash = "sha256-iRlwCSGigRi/ilfXi8rI68vlfkeec3vB5nZWPmTLnK8=";

  dontPatchElf = stdenv.isDarwin;

  nativeBuildInputs = [
    jq
    makeWrapper
    pkg-config
  ]
  ++ lib.optionals stdenv.isDarwin [ clang_20 ]; # clang_21 breaks @vscode/vsce's optionalDependencies keytar

  buildInputs = [
    ripgrep
    libsecret
  ];

  preConfigure = ''
    mkdir -p packages/cli/src/generated packages/core/src/generated
    cat > packages/cli/src/generated/git-commit.ts <<'GENEOF'
    export const GIT_COMMIT_INFO = '${finalAttrs.src.rev}';
    export const CLI_VERSION = '${finalAttrs.version}';
    GENEOF
    cp packages/cli/src/generated/git-commit.ts packages/core/src/generated/git-commit.ts
  '';

  postPatch = ''
    # Remove node-pty dependency from package.json
    ${jq}/bin/jq 'del(.optionalDependencies."node-pty")' package.json > package.json.tmp && mv package.json.tmp package.json

    # Remove node-pty dependency from packages/core/package.json
    ${jq}/bin/jq 'del(.optionalDependencies."node-pty")' packages/core/package.json > packages/core/package.json.tmp && mv packages/core/package.json.tmp packages/core/package.json

    # Fix ripgrep path for SearchText; ensureRgPath() on its own may return the path to a dynamically-linked ripgrep binary without required libraries
    substituteInPlace packages/core/src/tools/ripGrep.ts \
      --replace-fail "await ensureRgPath();" "'${lib.getExe ripgrep}';"

    # Disable auto-update by changing default values in settings schema
    sed -i '/enableAutoUpdate:/,/default: true/ s/default: true/default: false/' packages/cli/src/config/settingsSchema.ts
    sed -i '/enableAutoUpdateNotification:/,/default: true/ s/default: true/default: false/' packages/cli/src/config/settingsSchema.ts

    # Suppress TypeScript error for devtools dynamic import (runtime-only dependency, types not needed at build time)
    substituteInPlace packages/cli/src/utils/devtoolsService.ts \
      --replace-fail "const mod = await import('@google/gemini-cli-devtools');" "const mod = await import('@google/gemini-cli-devtools' as string);"

    # Also make sure the values are disabled in runtime code by changing condition checks to false
    substituteInPlace packages/cli/src/utils/handleAutoUpdate.ts \
      --replace-fail "if (!settings.merged.general.enableAutoUpdateNotification) {" "if (false) {" \
      --replace-fail "settings.merged.general.enableAutoUpdate," "false," \
      --replace-fail "!settings.merged.general.enableAutoUpdate" "!false"
  '';

  # Prevent npmDeps and python from getting into the closure
  disallowedReferences = [
    finalAttrs.npmDeps
    nodejs_22.python
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/gemini-cli}

    npm prune --omit=dev

    # Remove python files to prevent python from getting into the closure
    find node_modules -name "*.py" -delete
    # keytar/build has gyp-mac-tool with a Python shebang that gets patched,
    # creating a python3 reference in the closure
    rm -rf node_modules/keytar/build

    cp -r node_modules $out/share/gemini-cli/

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-devtools
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-sdk
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-test-utils
    rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
    cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
    cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    cp -r packages/a2a-server $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server
    cp -r packages/devtools $out/share/gemini-cli/node_modules/@google/gemini-cli-devtools
    cp -r packages/sdk $out/share/gemini-cli/node_modules/@google/gemini-cli-sdk

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core/dist/docs/CONTRIBUTING.md

    makeWrapper ${nodejs_22}/bin/node $out/bin/gemini \
      --add-flags "--no-warnings=DEP0040" \
      --add-flags "$out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js" \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]}

    # Clean up any remaining references to npmDeps in node_modules metadata
    find $out/share/gemini-cli/node_modules -name "package-lock.json" -delete
    find $out/share/gemini-cli/node_modules -name ".package-lock.json" -delete
    find $out/share/gemini-cli/node_modules -name "config.gypi" -delete

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    maintainers = with lib.maintainers; [
      brantes
      xiaoxiangmoe
      FlameFlag
      taranarmo
    ];
    platforms = lib.platforms.all;
    mainProgram = "gemini";
  };
})
