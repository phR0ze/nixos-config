# RustDesk with libxdo reachable at runtime
#
# RustDesk 1.5.0 switched to `libxdo-sys-stub`, which dlopen()s `libxdo.so.{4,3}` instead of linking
# it. The nixpkgs package only has xdotool as a build input, so the dlopen fails ("libxdo-sys libxdo
# not found, xdo functions will be disabled"). On X11 the server then can't inject mouse or keyboard
# input: remote sessions show the screen but you can't interact with it.
#
# An LD_LIBRARY_PATH wrapper isn't enough. The input-injecting `--server` process is started via
# `sudo ... app/rustdesk/rustdesk --server`, which skips the bin wrapper and strips the env. So
# xdotool goes on the runpath of librustdesk.so, the object that calls dlopen.
#
# This copies the prebuilt package and patches it rather than overriding the build, so the
# Rust/Flutter build isn't repeated. Drop it once nixpkgs adds xdotool to the runpath itself.
# --------------------------------------------------------------------------------------------------
{ lib, runCommand, patchelf, rustdesk-flutter, xdotool }:

runCommand rustdesk-flutter.name {
  nativeBuildInputs = [ patchelf ];
  inherit (rustdesk-flutter) meta;
  passthru = rustdesk-flutter.passthru or {};
} ''
  cp -a ${rustdesk-flutter} $out
  chmod -R u+w $out

  patchelf --add-rpath ${lib.getLib xdotool}/lib $out/app/rustdesk/lib/librustdesk.so

  # Point the wrapper at this copy, otherwise it execs the unpatched original
  substituteInPlace $out/bin/rustdesk --replace-fail ${rustdesk-flutter} $out
''
