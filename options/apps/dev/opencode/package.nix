# OpenCode configuration - uses pre-built binaries from GitHub releases
#
# ### Why not build from source?
# The standard nixpkgs approach builds opencode from source using bun. However, bun itself
# requires AVX2 CPU support and will crash with "Illegal instruction" on CPUs that only have
# AVX (not AVX2). Since this config targets machines without AVX2, we use the pre-built
# standalone executables released by the opencode project instead.
#
# ### Update instructions
# 1. run: ./get_new_version.sh
# 2. update `version` below
# 3. get new hashes:
#    nix-prefetch-url --type sha256 https://github.com/anomalyco/opencode/releases/download/v<version>/opencode-linux-x64.tar.gz
#    nix-prefetch-url --type sha256 https://github.com/anomalyco/opencode/releases/download/v<version>/opencode-linux-arm64.tar.gz
#    nix-prefetch-url --type sha256 https://github.com/anomalyco/opencode/releases/download/v<version>/opencode-darwin-x64.zip
#    nix-prefetch-url --type sha256 https://github.com/anomalyco/opencode/releases/download/v<version>/opencode-darwin-arm64.zip
#    nix hash convert --hash-algo sha256 --to base64 <hash>
#---------------------------------------------------------------------------------------------------
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  ripgrep,
  sysctl,
  unzip,
}:

let
  version = "1.4.3";

  srcMap = {
    "x86_64-linux" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-NNUD67AphTKTvm/U1EG7stuwORm/pFJeiLHKVdaPPhc=";
    };
    "aarch64-linux" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-arm64.tar.gz";
      hash = "sha256-TL8y9MMdp9rhRxK2Wq285qz6GnqFvumGos5Oqu1Otcg=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-x64.zip";
      hash = "sha256-FDECjjJNzdIyLlqnEERKUsbedNGjgvgIKkrRL9rgdo8=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
      hash = "sha256-0IXAcgh/oc8HYFiuKHhaMak2jg88QpheqMVYA2/Lmww=";
    };
  };

  srcData = srcMap.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

in stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    inherit (srcData) url hash;
  };

  nativeBuildInputs = [ makeWrapper ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ unzip ];

  sourceRoot = ".";

  # zip archives for darwin will extract to a dir or just opencode.
  # tar.gz for linux extracts just the opencode file.
  unpackPhase = ''
    runHook preUnpack
    if [[ "$src" == *.zip ]]; then
      unzip -q $src
    else
      tar -xf $src
    fi
    runHook postUnpack
  '';

  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/opencode
    # Bun standalone executables check /proc/self/exe to determine their entrypoint.
    # If the file is renamed (e.g. to .opencode-wrapped by wrapProgram), it falls back to the bun CLI.
    # Therefore, we place the binary in libexec/opencode/opencode and wrap it in bin/opencode.
    install -Dm755 opencode $out/libexec/opencode/opencode

    # Patch the executable before wrapping
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/libexec/opencode/opencode
    ''}

    makeWrapper $out/libexec/opencode/opencode $out/bin/opencode \
     --argv0 opencode \
     --prefix PATH : ${
       lib.makeBinPath (
         [ ripgrep ]
         ++ lib.optionals stdenv.hostPlatform.isDarwin [ sysctl ]
       )
     }

    runHook postInstall
  '';

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    maintainers = [];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "opencode";
  };
}
