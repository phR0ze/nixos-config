# Jellyfin desktop client wrapped to use EGL
#
# Under X11 Qt defaults to a GLX context, which the embedded libmpv can't share VA-API surfaces
# with ("VAAPI hwdec only works with OpenGL or Vulkan backends"), so it falls back to vaapi-copy:
# every decoded frame round trips through system RAM, pegging the CPU on low end hosts. Forcing
# Qt's EGL integration enables mpv's zero-copy EGL dmabuf interop. Wrapped via symlinkJoin rather
# than overriding qtWrapperArgs to avoid rebuilding the client from source.
#---------------------------------------------------------------------------------------------------
{ symlinkJoin, makeWrapper, jellyfin-desktop }:

symlinkJoin {
  name = "jellyfin-desktop-egl";
  paths = [ jellyfin-desktop ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/jellyfin-desktop --set QT_XCB_GL_INTEGRATION xcb_egl
  '';
}
