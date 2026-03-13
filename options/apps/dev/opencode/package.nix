# OpenCode configuration
#
# ### Update instructions
# 1. run: ./get_new_version.sh
# 2. update this file using the new version
# 3. get the new hashes using nix-prefetch-url
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
  version = "1.2.26";

  srcMap = {
    "x86_64-linux" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-PHpt0dxG4+OaYODi83EXb789loHim2cJkUkfEXIGJFQ=";
    };
    "aarch64-linux" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-arm64.tar.gz";
      hash = "sha256-wvOH3O9FE3nu3VFwLAKbGQZnqc9waQN9nRnyWLBZphw=";
    };
    "x86_64-darwin" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-x64.zip";
      hash = "sha256-lQyZGN9Mkj9rnphC+Bl0/TQb+/eT/adoEZxNFxWc3Ic=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-darwin-arm64.zip";
      hash = "sha256-IUuX9iP4cEeEaKrSvhWVRKsxLzNUsjQCx1rohT3j6CE=";
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
