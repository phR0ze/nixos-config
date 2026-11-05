# Immich Public Proxy, built from upstream's v4 source
#
# nixpkgs' package (3.4.0 at the time of writing) can't simply be overridden to v4: 4.0 split the
# repo into npm workspaces (`shared`, `app`, `upload-app`) under one root lockfile, so its
# `sourceRoot = app`, `npmDepsHash` and its `postPatch` (pointing a `views` dir v4 no longer has at
# the store) all stop applying. This follows upstream's Dockerfile instead:
#   - build `shared` (the `@ipp/core` workspace) and then `app`
#   - reinstall only `app`'s production dependencies, drop the workspace self-links and copy
#     `node_modules` with `cp -L`, so `@ipp/core` becomes a real directory rather than a symlink
#     back into the build tree
#   - ship `app/{package.json,dist,public,config.json}` beside it
# `public` is served relative to the working directory, so the wrapper `--chdir`s into the tree.
# `config.json` is found from `__dirname`, and the NixOS module overrides it with `IPP_CONFIG`.
# Every dependency is pure JavaScript, so `--ignore-scripts` (as `npmConfigHook` uses) loses nothing.
#
# Bumping: change `version`, reset `hash` and `npmDepsHash` to `lib.fakeHash`, build twice to get
# both, and diff upstream's Dockerfile for changes to the install steps above.
#---------------------------------------------------------------------------------------------------
{ lib, buildNpmPackage, fetchFromGitHub, makeWrapper, nodejs }:
buildNpmPackage (finalAttrs: {
  pname = "immich-public-proxy";
  version = "4.1.2";

  src = fetchFromGitHub {
    owner = "alangrainger";
    repo = "immich-public-proxy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MJ5VoBHXM5Mxch4nVaFk0B8/SNjkXf8oXQgnRwscc4E=";
  };

  npmDepsHash = "sha256-oKS034t7X0kJhVSRSUNyJRo3NDjjqP/LUm7rHl+6oSo=";

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild
    npm run build --workspace=shared --workspace=app
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    rm -rf node_modules
    npm ci --workspace=app --omit=dev --ignore-scripts --offline
    rm -rf node_modules/immich-public-proxy node_modules/immich-public-proxy-upload \
      node_modules/.bin/immich-public-proxy*

    dir=$out/lib/immich-public-proxy
    mkdir -p $dir
    cp -rL node_modules $dir/node_modules
    rm -rf $dir/node_modules/@ipp/core/{src,tests,tsconfig.json,vitest.config.ts,dist/tsconfig.tsbuildinfo}
    rm -f app/dist/tsconfig.tsbuildinfo
    cp -r app/package.json app/dist app/public app/config.json $dir/

    makeWrapper ${lib.getExe nodejs} $out/bin/immich-public-proxy \
      --chdir $dir \
      --set-default NODE_ENV production \
      --set-default APP_VERSION ${finalAttrs.version} \
      --add-flags $dir/dist/index.js

    runHook postInstall
  '';

  meta = {
    description = "Share Immich photos and albums publicly without exposing the Immich instance";
    homepage = "https://github.com/alangrainger/immich-public-proxy";
    changelog = "https://github.com/alangrainger/immich-public-proxy/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "immich-public-proxy";
    inherit (nodejs.meta) platforms;
  };
})
